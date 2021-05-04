defmodule Dudle.GameClientTest do
  use ExUnit.Case

  alias Dudle.{GameClient, GameServer}

  setup do
    {:ok, pid} = GameServer.start_link(data: %{room: "test_room"})
    {:ok, pid: pid}
  end

  test "server starts correctly", %{pid: pid} do
    assert {:lobby, %{room: "test_room", presence_players: []}} = :sys.get_state(pid)
  end
end
