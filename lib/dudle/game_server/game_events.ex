defmodule Dudle.GameServer.Events do
  @moduledoc """
  This module contains the implementation for all of the game server events
  """
  alias Dudle.Presence
  alias DudleWeb.Endpoint
  alias Dudle.Game

  @doc """
  Get a MapSet of the presence players in the room
  """
  @spec presence_players(String.t()) :: MapSet.t(String.t())
  def presence_players(room) do
    Presence.list("presence:#{room}") |> Map.keys() |> MapSet.new()
  end

  @spec construct_players_map(%{presence_players: MapSet.t(String.t())}) :: %{String.t() => %{}}
  def construct_players_map(%{presence_players: presence_players, game: nil} = _data) do
    Enum.map(presence_players, &{&1, %{online: true}}) |> Map.new()
  end

  def presence_diff(%{room: room} = data) do
    players = presence_players(room)

    {:keep_state, Map.put(data, :presence_players, players),
     [{:next_event, :internal, :broadcast_players}]}
  end

  def broadcast_players(state, %{room: room} = data) do
    Endpoint.broadcast("game:#{room}", "broadcast_players", construct_players_map(data))
    :keep_state_and_data
  end

  def start_game(from, :lobby, %{presence_players: players} = data) do
    new_data = %{data | game: Game.new(players)}
    {:next_state, :submit, new_data, [{:reply, from, {:ok, :server_started}}]}
  end
end
