defmodule Dudle.GameClient do
  @moduledoc """
  This module is the way to interact with a game server
  """

  alias Dudle.GameServer

  defp via(room) do
    {:via, Registry, {Dudle.GameRegistry, room}}
  end

  @spec start_server(String.t()) :: {:error, any()} | {:ok, any()}
  def start_server(room) do
    cond do
      String.length(room) > GameServer.room_name_limit() ->
        {:error,
         "Cannot join: room name's too long (under #{GameServer.room_name_limit()} characters please)"}

      String.length(room) < 1 ->
        {:error, "Cannot join: room name can't be empty"}

      :else ->
        case DynamicSupervisor.start_child(
               Dudle.GameSupervisor,
               {Dudle.GameServer, data: %{room: room}, name: via(room)}
             ) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          e -> e
        end
    end
  end

  def start_game(server, options) do
    GenStateMachine.call(server, {:start_game, options})
  end

  @doc """
  Try joining the game with the given player name
  """
  @spec join_game(GenServer.server(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def join_game(server, player) do
    GenStateMachine.call(server, {:join_game, player})
  end

  def get_state(server, player) do
    GenStateMachine.call(server, {:get_state, player})
  end

  def get_players(server) do
    GenStateMachine.call(server, :get_players)
  end

  def get_room_name(server) do
    GenStateMachine.call(server, :get_room_name)
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

  def reset_game(room) do
    for {pid, _} <- Registry.lookup(Dudle.GameRegistry, room) do
      DynamicSupervisor.terminate_child(Dudle.GameSupervisor, pid)
    end

    start_server(room)
  end
end
