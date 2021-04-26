defmodule Dudle.GameClient do
  @moduledoc """
  The set of client functions for interacting with the game server
  """

  defp via(name), do: {:via, Registry, {Dudle.GameRegistry, name}}

  defp call_name(room, call_data) do
    GenServer.call(via(room), call_data)
  end

  @doc """
  Add a player to the game. This function only works in the lobby.
  """
  def add_player(name, player) do
    Dudle.GameServer.start_server(name)
    call_name(name, {:add_player, player})
  end

  # @doc """
  # Get the full state of the game.
  # """
  # def get_full_state(name) do
  #   call_name(name, :get_full_state)
  # end

  def submit_image(room, player, image_data) do
    call_name(room, {:submit_prompt, {:image, player, image_data}})
  end

  def submit_text(room, player, text) do
    call_name(room, {:submit_prompt, {:text, player, text}})
  end

  def get_state(room, name) do
    call_name(room, {:get_state, name})
  end

  @doc """
  Start the game. At least one player needs to be there to start.
  """
  def start_game(name) do
    call_name(name, :start_game)
  end

  def reveal_next(name) do
    call_name(name, :next_review_state)
  end

  def ensure_server_started(name) do
    case Dudle.GameServer.start_server(name) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      _ -> {:error, "couldn't start server"}
    end
  end
end
