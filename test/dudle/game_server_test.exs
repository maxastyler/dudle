defmodule Dudle.GameServerTest do
  use ExUnit.Case
  doctest Dudle.GameServer

  alias Dudle.GameServer
  alias Dudle.Game

  test "adding submissions to round adds correctly" do
    round = %{
      next_players: %{"alice" => "bob", "bob" => "alice"},
      prompts: %{"alice" => {"prompt 1", []}, "bob" => {"prompt 2", []}}
    }

    assert {{:playing, :creating}, %{}} =
             GameServer.add_submissions_to_round(round, %{"alice" => "sub 1", "bob" => "sub 2"})
  end
end
