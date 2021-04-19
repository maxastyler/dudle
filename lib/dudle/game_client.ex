defmodule Dudle.GameClient do

  @moduledoc """
  The set of client functions for interacting with the game server
  """

  defp via(name), do: {:via, Registry, {Dudle.GameRegistry, name}}

  defp call_name(name, call_data) do
    GenServer.call(via(name), call_data)
  end

  @doc """
  Add a player to the game. This function only works in the lobby.
  """
  def add_player(name, player) do
    Dudle.GameServer.start_server(name)
    call_name(name, {:add_player, player})
  end

  @doc """
  Get the full state of the game.
  """
  def get_full_state(name) do
    call_name(name, :get_full_state)
  end

  @doc """
  Start the game. At least one player needs to be there to start.
  """
  def start_game(name) do
    call_name(name, :start_game)
  end

  def ensure_server_started(name) do
    case Dudle.GameServer.start_server(name) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      _ -> {:error, "couldn't start server"}
    end
  end

end
