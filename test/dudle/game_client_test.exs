defmodule Dudle.GameClientTest do
  use ExUnit.Case

  alias Dudle.{GameClient, GameServer, Game, Prompt}

  setup do
    room = "test_room"

    {:ok, player_1} =
      Agent.start_link(fn -> Dudle.Presence.track(self(), "presence:#{room}", "player_1", %{}) end)

    {:ok, player_2} =
      Agent.start_link(fn -> Dudle.Presence.track(self(), "presence:#{room}", "player_2", %{}) end)

    {:ok, pid} = GameServer.start_link(data: %{room: room})
    {:ok, pid: pid, player_1: player_1, player_2: player_2, room: room}
  end

  test "server starts correctly", %{pid: pid} do
    assert {:lobby, %{room: "test_room"}} = :sys.get_state(pid)
  end

  test "server accepts joined players", %{pid: pid, room: room} do
    DudleWeb.Endpoint.subscribe("game:#{room}")

    assert {:lobby,
            %{
              room: room,
              presence_players: MapSet.new(["player_1", "player_2"]),
              game: nil
            }} ==
             :sys.get_state(pid)

    Dudle.Presence.track(self(), "presence:#{room}", "new_player", %{})
    Process.sleep(100)

    assert {:lobby,
            %{
              room: room,
              presence_players: MapSet.new(["player_1", "player_2", "new_player"]),
              game: nil
            }} ==
             :sys.get_state(pid)

    player_map =
      for(p <- ["player_1", "player_2", "new_player"], into: %{}, do: {p, %{online: true}})

    assert_receive %{
      event: "broadcast_players",
      payload: player_map
    }
  end

  test "game doesn't start with less than two players", %{pid: pid, player_1: player_1} do
    Agent.stop(player_1)
    Process.sleep(200)
    assert {:error, _} = GameClient.start_game(pid)
  end

  test "can't submit when game hasn't started", %{pid: pid} do
    assert {:error, _} = GameClient.submit_prompt(pid, Prompt.new(:text, "test", "hi"))
  end

  test "valid game can be played", %{pid: pid, room: room} do
    DudleWeb.Endpoint.subscribe("game:#{room}")
    assert :lobby = GameClient.get_state(pid, "player_1")
    assert {:ok, :game_started} = GameClient.start_game(pid)
    assert {:submit, %{game: %Game{}}} = :sys.get_state(pid)
    assert_receive %{event: "broadcast_state", payload: :state_updated}, 300

    assert {:submit, %Prompt{type: text, submitter: :initial}} =
             GameClient.get_state(pid, "player_1")

    assert {:submit, %Prompt{type: text, submitter: :initial}} =
             GameClient.get_state(pid, "player_2")

    prompt = Prompt.new(:image, "player_1", "im")
    assert {:ok, prompt} = GameClient.submit_prompt(pid, prompt)
    prompt = Prompt.new(:image, "player_2", "im")
    assert {:ok, prompt} = GameClient.submit_prompt(pid, prompt)

    Process.sleep(100)
    prompt = Prompt.new(:image, "player_1", "im")
    assert {:ok, prompt} = GameClient.submit_prompt(pid, prompt)
    prompt = Prompt.new(:image, "player_2", "im")
    assert {:ok, prompt} = GameClient.submit_prompt(pid, prompt)
    IO.inspect(:sys.get_state(pid))
  end
end
