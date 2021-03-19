defmodule Dudle.GameClientTest do
  use ExUnit.Case
  doctest Dudle.GameClient

  alias Dudle.GameServer
  alias Dudle.GameClient
  alias Dudle.Game

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
    assert GameClient.get_full_state(@server_name) == {:lobby, %{players: MapSet.new()}}
  end

  test "adds player correctly" do
    GameClient.add_player(@server_name, "alice")
    GameClient.add_player(@server_name, "bob")
    assert GameClient.get_full_state(@server_name) == {:lobby, %{players: MapSet.new(["alice", "bob"])}}
  end

  test "doesn't start game when there are no players" do
    assert {:error, _} = GameClient.start_game(@server_name)
  end

  test "starts game with players" do
    GameClient.add_player(@server_name, "alice")
    assert :ok = GameClient.start_game(@server_name)
    assert {{:playing, :creating}, %{game: %Game{}}} = GameClient.get_full_state(@server_name)
  end

end
