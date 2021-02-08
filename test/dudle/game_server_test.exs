defmodule Dudle.GameServerTest do
  use ExUnit.Case
  doctest Dudle.GameServer

  alias Dudle.GameServer

  @server_name "test_server"

  setup_all do
    Registry.start_link(keys: :unique, name: Dudle.GameRegistry)
    DynamicSupervisor.start_link(strategy: :one_for_one, name: Dudle.GameSupervisor)
    :ok
  end

  setup do
    with [{pid, nil}] <- Registry.lookup(Dudle.GameRegistry, @server_name) do
      DynamicSupervisor.terminate_child(Dudle.GameSupervisor, pid)
    end

    GameServer.start_server(@server_name)
    :ok
  end

  test "initialises server correctly" do
    assert GameServer.state(@server_name) == {:lobby, %{players: MapSet.new()}}
  end

  test "adds player correctly" do
    GameServer.add_player(@server_name, "alice")
    GameServer.add_player(@server_name, "bob")
    assert GameServer.state(@server_name) == {:lobby, %{players: MapSet.new(["alice", "bob"])}}
  end

  test "removes player correctly" do
    GameServer.add_player(@server_name, "alice")
    GameServer.add_player(@server_name, "bob")
    GameServer.remove_player(@server_name, "bob")
    assert GameServer.state(@server_name) == {:lobby, %{players: MapSet.new(["alice"])}}
  end

  test "starts game correctly" do
    GameServer.add_player(@server_name, "alice")
    assert {:error, _} = GameServer.start_game(@server_name)
    GameServer.add_player(@server_name, "bob")
    assert {:ok, _} = GameServer.start_game(@server_name)
    assert {:in_game, %{game: %Dudle.Game{}, submitted: %{}}} = GameServer.state(@server_name)
  end

  test "submitting turns" do
    GameServer.add_player(@server_name, "alice")
    GameServer.add_player(@server_name, "bob")
    GameServer.start_game(@server_name)

    GameServer.submit_turn(@server_name, "alice", 2)
    GameServer.submit_turn(@server_name, "bob", 3)

    assert {:in_game,
            %{
              game: %Dudle.Game{
                rounds: [
                  %{prompts: %{"alice" => {_, [{"alice", 2}]}, "bob" => {_, [{"bob", 3}]}}} | _
                ]
              },
              submitted: %{}
            }} = GameServer.state(@server_name)
  end

  test "Getting prompt" do
    GameServer.add_player(@server_name, "alice")
    GameServer.add_player(@server_name, "bob")
    GameServer.start_game(@server_name)

    # assert GameServer.state(@server_name) == 2
    assert {:ok, _} = GameServer.get_prompt(@server_name, "bob")

    GameServer.submit_turn(@server_name, "alice", 2)
    GameServer.submit_turn(@server_name, "bob", 3)
    assert GameServer.get_prompt(@server_name, "alice") == {:ok, 3}
    assert GameServer.get_prompt(@server_name, "bob") == {:ok, 2}
  end
end
