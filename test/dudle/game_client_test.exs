defmodule Dudle.GameClientTest do
  use ExUnit.Case

  alias Dudle.{GameClient, GameServer, Game, Prompt, Round}

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
              presence_players: _,
              game: nil
            }} = :sys.get_state(pid)

    Dudle.Presence.track(self(), "presence:#{room}", "new_player", %{})
    Process.sleep(100)

    assert {:lobby,
            %{
              room: room,
              presence_players: _,
              game: nil
            }} = :sys.get_state(pid)

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

  test "getting players works correctly", %{pid: pid, room: room} do
    DudleWeb.Endpoint.subscribe("game:#{room}")
    assert :lobby = GameClient.get_state(pid, "player_1")
    initial_map = Enum.map(["player_1", "player_2"], &{&1, %{online: true}}) |> Map.new()
    assert initial_map == GameClient.get_players(pid)
    assert {:ok, :game_started} = GameClient.start_game(pid)
    assert {:submit, %{game: %Game{}}} = :sys.get_state(pid)
    assert_receive %{event: "broadcast_state", payload: :state_updated}, 300

    assert {:submit, %Prompt{type: text, submitter: :initial}} =
             GameClient.get_state(pid, "player_1")

    assert {:submit, %Prompt{type: text, submitter: :initial}} =
             GameClient.get_state(pid, "player_2")

    prompt = Prompt.new(:text, "player_1", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)
    prompt = Prompt.new(:text, "player_2", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)

    Process.sleep(100)

    new_map =
      Enum.map(["player_1", "player_2"], &{&1, %{online: true, score: 0, submitted: false}})
      |> Map.new()

    assert new_map == GameClient.get_players(pid)
    prompt = Prompt.new(:text, "player_1", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)
    prompt = Prompt.new(:text, "player_2", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)
    assert {:error, "not in submitting state"} = GameClient.submit_prompt(pid, prompt)
    Process.sleep(100)

    new_map =
      Enum.map(["player_1", "player_2"], &{&1, %{online: true, score: 0}})
      |> Map.new()

    assert new_map == GameClient.get_players(pid)
    [first_player, second_player] = (:sys.get_state(pid) |> elem(1)).game.players
    assert {:error, _} = GameClient.advance_review_state(pid, "not in the game player")
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert {:error, _} = GameClient.advance_review_state(pid, first_player)
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

    prompt = Prompt.new(:text, "player_1", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)
    prompt = Prompt.new(:text, "player_2", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)

    Process.sleep(100)
    prompt = Prompt.new(:text, "player_1", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)
    prompt = Prompt.new(:text, "player_2", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)
    assert {:error, "not in submitting state"} = GameClient.submit_prompt(pid, prompt)
    Process.sleep(100)

    [first_player, second_player] = (:sys.get_state(pid) |> elem(1)).game.players
    assert {:error, _} = GameClient.advance_review_state(pid, "not in the game player")
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert {:error, _} = GameClient.advance_review_state(pid, first_player)

    assert {:error, _} = GameClient.submit_correct(pid, "not in the game", true)
    assert :ok = GameClient.submit_correct(pid, first_player, true)
    assert {:error, _} = GameClient.submit_vote(pid, first_player, first_player)
    assert :ok = GameClient.submit_vote(pid, first_player, second_player)
    assert {:error, _} = GameClient.submit_vote(pid, first_player, second_player)

    assert {:error, _} = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.advance_review_state(pid, second_player)
    assert :ok = GameClient.advance_review_state(pid, second_player)
    assert :ok = GameClient.advance_review_state(pid, second_player)
    assert :ok = GameClient.advance_review_state(pid, second_player)
    assert {:error, _} = GameClient.advance_review_state(pid, second_player)
    assert :ok = GameClient.submit_correct(pid, second_player, false)
    assert :ok = GameClient.submit_vote(pid, second_player, first_player)
    assert {:error, _} = GameClient.submit_vote(pid, second_player, first_player)

    assert {:submit, %Prompt{}} = GameClient.get_state(pid, first_player)
  end

  test "score limits work", %{pid: pid} do
    GameClient.set_score_limit(pid, 2)
    GameClient.start_game(pid)
    prompt = Prompt.new(:text, "player_1", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)
    prompt = Prompt.new(:text, "player_2", "")
    assert {:error, _} = GameClient.submit_prompt(pid, prompt)
    prompt = Prompt.new(:text, "player_2", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)

    prompt = Prompt.new(:text, "player_1", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)
    prompt = Prompt.new(:text, "player_2", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)

    [first_player, second_player] = (:sys.get_state(pid) |> elem(1)).game.players
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.submit_correct(pid, first_player, true)
    assert :ok = GameClient.submit_vote(pid, first_player, second_player)
    assert :ok = GameClient.advance_review_state(pid, second_player)
    assert :ok = GameClient.advance_review_state(pid, second_player)
    assert :ok = GameClient.advance_review_state(pid, second_player)
    assert :ok = GameClient.advance_review_state(pid, second_player)
    assert :ok = GameClient.submit_correct(pid, second_player, true)
    assert :ok = GameClient.submit_vote(pid, second_player, first_player)
    assert {:end, %{"player_1" => _, "player_2" => _}} = GameClient.get_state(pid, first_player)
  end

  test "round limits work", %{pid: pid} do
    GameClient.set_round_limit(pid, 1)
    GameClient.start_game(pid)
    prompt = Prompt.new(:text, "player_1", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)
    prompt = Prompt.new(:text, "player_2", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)

    prompt = Prompt.new(:text, "player_1", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)
    prompt = Prompt.new(:text, "player_2", "im")
    assert :ok = GameClient.submit_prompt(pid, prompt)

    [first_player, second_player] = (:sys.get_state(pid) |> elem(1)).game.players
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.advance_review_state(pid, first_player)
    assert :ok = GameClient.submit_correct(pid, first_player, true)
    assert :ok = GameClient.submit_vote(pid, first_player, second_player)
    assert :ok = GameClient.advance_review_state(pid, second_player)
    assert :ok = GameClient.advance_review_state(pid, second_player)
    assert :ok = GameClient.advance_review_state(pid, second_player)
    assert :ok = GameClient.advance_review_state(pid, second_player)
    assert :ok = GameClient.submit_correct(pid, second_player, true)
    assert :ok = GameClient.submit_vote(pid, second_player, first_player)
    assert {:end, %{"player_1" => _, "player_2" => _}} = GameClient.get_state(pid, first_player)
  end

  test "joining the game works as expected", %{pid: pid} do
    assert {:ok, "hiyi"} == GameClient.join_game(pid, "hiyi")
    assert {:error, _} = GameClient.join_game(pid, "hiyi")
    assert {:ok, "hoyo"} == GameClient.join_game(pid, "hoyo")
    n = String.duplicate("h", GameServer.player_name_limit() + 1)
    lim = GameServer.player_name_limit()
    sliced = String.slice(n, 0, lim)
    assert {:error, _} = GameClient.join_game(pid, n)
  end
end
