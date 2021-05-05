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

  def advance_review_state(server, player) do
    GenStateMachine.call(server, {:advance_review_state, player})
  end

  def submit_correct(server, player, correct) do
    GenStateMachine.call(server, {:submit_correct, player, correct})
  end

  def submit_vote(server, player, vote) do
    GenStateMachine.call(server, {:submit_vote, player, vote})
  end

  def set_score_limit(server, limit) do
    GenStateMachine.call(server, {:set_score_limit, limit})
  end

  def set_round_limit(server, limit) do
    GenStateMachine.call(server, {:set_round_limit, limit})
  end
end
