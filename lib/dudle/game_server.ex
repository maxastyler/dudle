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

  {:playing, :submitting}
  {:playing, {:reviewing, :reviewing}}
  {:playing, {:reviewing, :voting}}

  :end


  """
  use GenStateMachine

  alias Dudle.Game
  alias Dudle.Round
  alias DudleWeb.Endpoint
  import Access, only: [key: 1, key: 2, at: 1]

  @prompts ["Prompt 1", "Stinky prompt", "An incredibly cool picture", "Very very cool"]

  defp notify_of_change(%{room: room} = _data) do
    DudleWeb.Endpoint.broadcast("game:#{room}", "data_update", :data_update)
    :ok
  end

  defp notify_review_change(%{room: room, game: game} = _data) do
    DudleWeb.Endpoint.broadcast(
      "game:#{room}",
      "review_update",
      {game.round.review_state, Round.get_review_prompt(game.round)}
    )

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

  @impl true
  def handle_event({:call, from}, :start_game, :lobby, %{players: players} = data) do
    IO.puts("Start game")

    case MapSet.size(players) do
      0 ->
        {:keep_state_and_data, {:reply, from, {:error, "Can't start game with no players"}}}

      _ ->
        with {:ok, game} <- Game.new_game(players, @prompts) do
          new_data = Map.put(data, :game, game)

          {:next_state, {:playing, :submitting}, new_data,
           [{:reply, from, :ok}, {:next_event, :internal, :notify}]}
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
        _state,
        %{room: room} = data
      ) do
    {:keep_state,
     %{
       data
       | players:
           Dudle.Presence.list("presence:#{room}") |> Map.keys() |> Enum.sort() |> MapSet.new()
     }}
  end

  def handle_event({:call, from}, {:get_state, _player}, :lobby, _data) do
    {:keep_state_and_data, {:reply, from, {:lobby, :lobby}}}
  end

  def handle_event({:call, from}, {:get_state, player}, {:playing, :submitting} = state, data) do
    {:keep_state_and_data, {:reply, from, {state, Game.get_prompt(data.game, player)}}}
  end

  # return to the player a tuple {state, review_state, current_prompt}
  def handle_event(
        {:call, from},
        {:get_state, _player},
        {:playing, :reviewing} = state,
        data
      ) do
    {:keep_state_and_data,
     {:reply, from,
      {state, data.game.round.review_state, Round.get_review_prompt(data.game.round)}}}
  end

  ##### {:playing, :reviewing} events

  def handle_event(
        {:call, from},
        {:submit_prompt, {_, player, _} = prompt_data},
        {:playing, :submitting},
        data
  ) do
    new_data =
      Map.update(
        data,
        :turn_submissions,
        %{player => prompt_data},
        &Map.put(&1, player, prompt_data)
      )

    if map_size(new_data.turn_submissions) >= length(new_data.game.players) do
      # all the submissions are in
      {:keep_state, new_data,
       [{:reply, from, :ok}, {:next_event, :internal, :insert_submissions}]}
    else
      {:keep_state, new_data, {:reply, from, :ok}}
    end
  end

  def handle_event(
        :internal,
        :insert_submissions,
        _state,
        %{turn_submissions: subs, game: game} = data
      ) do
    new_game = Game.add_submissions(game, subs)
    new_data = Map.put(data, :turn_submissions, %{})

    if Game.round_complete?(new_game) do
      {:next_state, {:playing, :reviewing},
       Map.put(
         new_data,
         :game,
         Map.update!(new_game, :round, &Round.convert_to_reviewing_state(&1, new_game.players))
       ), [{:next_event, :internal, :notify_review}]}
    else
      {:keep_state, Map.put(new_data, :game, new_game), [{:next_event, :internal, :notify}]}
    end
  end

  def handle_event(:internal, :notify, _state, data) do
    notify_of_change(data)
    {:keep_state_and_data, []}
  end

  def handle_event(:internal, :notify_review, _state, data) do
    notify_review_change(data)
    {:keep_state_and_data, []}
  end

  def handle_event({:call, from}, :next_review_state, {:playing, :reviewing}, data) do
    case Round.get_next_review_state(data.game.round) do
      :finished ->
        with {:ok, new_round} <- Round.new_round(data.game.players, data.game.prompts),
             new_data <-
               update_in(data, [:game, :previous_rounds], &[data.game.round | &1])
               |> put_in([:game, :round], new_round) do
          {:next_state, {:playing, :submitting}, new_data,
           [{:reply, from, :ok}, {:next_event, :internal, :notify}]}
        end

      new_round ->
        {:keep_state, put_in(data, [:game, :round], new_round),
         [{:reply, from, :ok}, {:next_event, :internal, :notify_review}]}
    end
  end

  ##### :end events
end
