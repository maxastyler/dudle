defmodule Dudle.GameServer do
  @moduledoc """

  TODO::: Refactor this into two separate parts: a game state (server state or whatever) and a presentation state
  The game state should contain stuff to do specifically with the game (submissions, etc...)
  The presentation state should contain stuff to do with presenting this data to the users (pubsub, reviewing submissions, voting etc...)

  This module defines a server which runs a single game.
  It runs on a state machine

  The different states of the machine are:
  :lobby - waiting in the lobby, we can add more players at this point
  :playing 

  The data in the state machine at all points should carry the data
  %{game: %Game, round: Round, submissions: [submission], }

  Different states in the game:

  :lobby

  {:playing, :creating}
  {:playing, {:reviewing, :revealing}}
  {:playing, {:reviewing, :voting}}

  :end


  """
  use GenStateMachine

  alias Dudle.Game
  alias Dudle.Round
  alias DudleWeb.Endpoint
  import Access, only: [key: 1, key: 2, at: 1]

  @prompts ["Prompt 1", "Stinky prompt", "An incredibly cool picture", "Very very cool"]

  defp broadcast_data(%{room: room} = data) do
    DudleWeb.Endpoint.broadcast("game:#{room}", "data_update", data)
    :ok
  end

  def start_link(options) do
    {data, opts} = Keyword.pop(options, :data)
    GenStateMachine.start_link(__MODULE__, data, opts)
  end

  @impl true
  def init(%{room: room} = data) do
    DudleWeb.Endpoint.subscribe("presence:#{room}")
    {:ok, :lobby, data}
  end

  defp via(name), do: {:via, Registry, {Dudle.GameRegistry, name}}

  @doc """
  Start a game server with a given name
  """
  def start_server(name) do
    DynamicSupervisor.start_child(
      Dudle.GameSupervisor,
      {Dudle.GameServer, data: %{players: MapSet.new(), room: name}, name: via(name)}
    )
  end

  ##### :lobby events

  def handle_event({:call, from}, :start_game, :lobby, %{players: players} = data) do
    case MapSet.size(players) do
      0 ->
        {:keep_state_and_data, {:reply, from, {:error, "Can't start game with no players"}}}

      _ ->
        with {:ok, new_data} <- Game.new_game_state(players) do
          new_data = Map.merge(data, new_data)
          {:next_state, {:playing, :creating}, new_data, {:reply, from, :ok}}
        else
          {:error, error} -> {:keep_state_and_data, {:reply, from, {:error, error}}}
        end
    end
  end

  def handle_event({:call, from}, :start_game, {:playing, _}, _),
    do: {:keep_state_and_data, {:reply, from, :ok}}

  def handle_event(
        :info,
        %{event: "presence_diff"},
        :lobby,
        %{room: room} = data
      ) do
    {:keep_state,
     %{
       data
       | players:
           Dudle.Presence.list("presence:#{room}") |> Map.keys() |> Enum.sort() |> MapSet.new()
     }}
  end

  def handle_event({:call, from}, {:get_state, player}, {:playing, :submitting} = state, data) do
    {:keep_state_and_data, {:reply, from, {state, Game.get_prompt(data, player)}}}
  end

  def handle_event({:call, from}, {:get_state, player}, {:playing, :revealing} = state, data) do
    {:keep_state_and_data, {:reply, from, {}}}
  end

  ##### {:playing, :revealing} events

  ##### :end events
end
