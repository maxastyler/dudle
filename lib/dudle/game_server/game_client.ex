defmodule Dudle.GameClient do
  @moduledoc """
  This module is the way to interact with a game server
  """

  alias Dudle.GameServer

  def start_game(server) do
    GenStateMachine.call(server, :start_game)
  end
end
