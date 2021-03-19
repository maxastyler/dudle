defmodule Dudle.GameServer do
  @moduledoc """
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
  use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

  alias Dudle.Game
  alias DudleWeb.Endpoint
  import Access, only: [key: 1, key: 2, at: 1]

  @prompts ["Prompt 1", "Stinky prompt", "An incredibly cool picture", "Very very cool"]

  def start_link(options) do
    {data, opts} = Keyword.pop(options, :data)
    GenStateMachine.start_link(__MODULE__, {:lobby, data}, opts)
  end

  @impl true
  def init({state, data}), do: {:ok, state, data}

  defp via(name), do: {:via, Registry, {Dudle.GameRegistry, name}}

  @doc """
  Start a game server with a given name
  """
  def start_server(name) do
    DynamicSupervisor.start_child(
      Dudle.GameSupervisor,
      {Dudle.GameServer, data: %{players: MapSet.new()}, name: via(name)}
    )
  end

  @doc """
  Create the game state required when a new game is created
  """
  def new_game_state(players, prompts \\ @prompts) do
    with {:ok, %Game{rounds: [r | rs]} = game} <-
           Game.new_round(%Game{players: MapSet.to_list(players)}, prompts) do
      {:ok,
       %{submissions: empty_submissions_map(players), round: r, game: %Game{game | rounds: rs}}}
    else
      e -> e
    end
  end

  @doc """
  Create an empty submissions map from the players in the game
  """
  def empty_submissions_map(players), do: Map.new(players, &{&1, nil})

  @doc """
  Add the new submissions to the round.
  Returns a tuple of {new_state, new_round}
  If all submissions have been completed for the round, move on to the reviewing state.
  """
  def add_submissions_to_round(
        %{next_players: next_players, prompts: prompts} = round,
        new_submissions
      ) do
    num_players = map_size(next_players)

    {new_size, new_prompts} =
      for {player, submission} <- new_submissions, reduce: {num_players, prompts} do
        {smallest_size, p} ->
          get_and_update_in(
            p,
            [player, Access.elem(1)],
            &{min(smallest_size, length(&1) + 1), [{player, submission} | &1]}
          )
      end

    {{:playing, if(new_size >= num_players, do: {:reviewing, :revealing}, else: :creating)},
     %{round | prompts: new_prompts}}
  end

  def handle_event({:call, from}, :get_full_state, state, data) do
    {:keep_state_and_data, {:reply, from, {state, data}}}
  end

  ##### :lobby events

  @impl true
  def handle_event({:call, from}, {:add_player, player}, :lobby, data) do
    new_data = update_in(data, [:players], &MapSet.put(&1, player))
    {:keep_state, new_data, {:reply, from, {:ok, new_data}}}
  end

  def handle_event({:call, from}, {:remove_player, player}, :lobby, data) do
    new_data = update_in(data, [:players], &MapSet.delete(&1, player))
    {:keep_state, new_data, {:reply, from, {:ok, new_data}}}
  end

  def handle_event({:call, from}, :start_game, :lobby, %{players: players} = data) do
    case MapSet.size(players) do
      0 ->
        {:keep_state_and_data, {:reply, from, {:error, "Can't start game with no players"}}}

      _ ->
        with {:ok, new_data} <- new_game_state(players) do
          {:next_state, {:playing, :creating}, Map.merge(data, new_data), {:reply, from, :ok}}
        else
          {:error, error} -> {:keep_state_and_data, {:reply, from, {:error, error}}}
        end
    end
  end

  ##### {:playing, :creating} events

  def handle_event(
        {:call, from},
        {:submit, player, submission},
        {:playing, :creating},
        %{submissions: submissions, round: round, game: %Game{players: players}} = data
      ) do
    new_submissions = Map.put(submissions, player, submission)
    # if all submissions are in:
    if Map.values(new_submissions) |> Enum.all?() do
      {state, round} = add_submissions_to_round(round, new_submissions)
      new_data = %{data | submissions: empty_submissions_map(players), round: round}

      case state do
        {_, :creating} ->
          {:keep_state, new_data, {:reply, from, :ok}}

        _ ->
          {:new_state_and_data, {:playing, {:reviewing, :voting}}, new_data, {:reply, from, :ok}}
      end
    else
      {:keep_state, %{data | submissions: new_submissions}, {:reply, from, :ok}}
    end
  end

  ##### {:playing, {:reviewing, :revealing}} events

  # def handle_event(
  #       {:call, from},
  #       {:reveal, player},
  #       {:playing, {:reviewing, :revealing}},
  #       data
  #     ) do
  #   {:new_state_and_data, {:playing, {:reviewing, :voting}}, %{data, }}
  # end

  ##### {:playing, {:reviewing, :voting}} events

  # def handle_event(:enter, _old_state, {:playing, {:reviewing, :voting}}, data) do
  # end

  def handle_event(
        {:call, from},
        {:vote, from_player, for_player, vote_type},
        {:playing, {:reviewing, :voting}},
        %{round: round, game: %Game{players: players}} = data
      ) do
    {votes_count, new_data} =
      Access.get_and_update(data, :votes, fn
        nil ->
          {1, %{from_player => {vote_type, for_player}}}

        votes ->
          new_votes = Map.put(votes, from_player, {vote_type, for_player})
          {map_size(new_votes), new_votes}
      end)

    if votes_count >= length(players) do
      round
    else
      {:keep_data, {:playing, :creating}, {:reply, from, :ok}}
    end
  end

  ##### :end events
end
