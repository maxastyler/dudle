defmodule Dudle.GameClient do
  @moduledoc """
  This module is the way to interact with a game server
  """

  alias Dudle.GameServer

  def start_game(server) do
    GenStateMachine.call(server, :start_game)
  end

  def get_state(server, player) do
    GenStateMachine.call(server, {:get_state, player})
  end

  def submit_prompt(server, prompt) do
    GenStateMachine.call(server, {:submit_prompt, prompt})
  end
end
