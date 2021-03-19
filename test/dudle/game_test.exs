defmodule Dudle.GameTest do
  use ExUnit.Case
  doctest Dudle.Game

  alias Dudle.Game

  test "hi there this is a test" do
    assert {:ok, %{next_players: %{"alice" => "bob", "bob" => "alice"}, prompts: %{}}} =
             Game.new_round(["alice", "bob"], ["p1", "p2", "p3"])
  end
end
