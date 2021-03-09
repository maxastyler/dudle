defmodule Dudle.GameServer do
  @moduledoc """
  This module defines a server which runs a single game.
  It runs on a state machine

  The different states of the machine are:
  :lobby - waiting in the lobby, we can add more players at this point
  :playing 
  
  """
  use GenStateMachine

  alias Dudle.Game
  alias DudleWeb.Endpoint
  import Access, only: [key: 1, key: 2, at: 1]

  def start_link(options) do
    {data, opts} = Keyword.pop(options, :data)
    GenStateMachine.start_link(__MODULE__, {:lobby, data}, opts)
  end

  @impl true
  def init({state, data}), do: {:ok, state, data}

  defp via(name), do: {:via, Registry, {Dudle.GameRegistry, name}}

  @doc """
  We either start a new turn (if the prompts haven't been filled for every player yet) or
  a new round (if they have)
  """
  defp finish_current_turn(data) do
    num_players = get_in(state, [:game, key(:players)]) |> length()

    new_state =
      state
      |> update_in(
        [:game, key(:rounds), at(0), :prompts],
        &for {p, {o, l}} <- &1, into: %{} do
          {p, {o, [{p, state.submitted[p]} | l]}}
        end
      )
      |> put_in([:submitted], %{})

    finished_round =
      get_in(new_state, [:game, key(:rounds), at(0), :prompts])
      |> Enum.all?(fn {_, {_, l}} -> length(l) == num_players end)

    if finished_round do
      update_in(new_state, [:game], &Game.new_round(&1))
    else
      new_state
    end
  end

  @doc """
  Start a game server with a given name
  """
  def start_server(name) do
    DynamicSupervisor.start_child(
      Dudle.GameSupervisor,
      {Dudle.GameServer, data: %{players: MapSet.new()}, name: via(name)}
    )
  end

  @impl true
  def handle_call(:start_game, _from, {:lobby, data}) do
    if MapSet.size(data.players) > 1 do
      {:ok, game} =
        %Game{players: MapSet.to_list(data.players) |> Enum.sort()} |> Game.new_round()
      Endpoint.broadcast()
      {:reply, {:ok, nil}, {:in_game, %{game: game, submitted: %{}}}}
    else
      {:reply, {:error, "Can't start game with less than 2 players"}, {:lobby, data}}
    end
  end

  def handle_call({:add_player, player}, _from, {:lobby, data}) do
    {:reply, {:ok, nil}, {:lobby, update_in(data, [:players], &MapSet.put(&1, player))}}
  end

  def handle_call({:remove_player, player}, _from, {:lobby, data}) do
    {:reply, {:ok, nil}, {:lobby, update_in(data, [:players], &MapSet.delete(&1, player))}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:submit_turn, player, turn_data}, _from, {:in_game, data}) do
    new_state = update_in(data, [:submitted], &Map.put(&1, player, turn_data))

    {:reply, :ok,
     {:in_game,
      if map_size(new_state.submitted) == length(new_state.game.players) do
        finish_current_turn(new_state)
      else
        new_state
      end}}
  end

  @impl true
  def handle_call({:get_prompt, player}, _from, {:in_game, data}) do
    # find the previous player who maps
    prev_player =
      get_in(data, [:game, key(:rounds), at(0), :next_players])
      |> Enum.find(fn {_, val} -> val == player end)
      |> elem(0)

    prompts = get_in(data, [:game, key(:rounds), at(0), :prompts])

    description =
      with {_, description} <-
             Map.values(prompts)
             |> Enum.map(
               &case elem(&1, 1) |> List.first(),
                 do:
                   (
                     nil -> {nil, nil}
                     x -> x
                   )
             )
             |> Enum.find(fn {p, _} -> p == prev_player end) do
        description
      else
        _ -> prompts[player] |> elem(0)
      end

    {:reply, {:ok, description}, {:in_game, data}}
  end

  def call_name(name, call), do: GenServer.call(via(name), call)

  # client functions

  @doc """
  Start a game on a server that's in a lobby. 
  Errors if there's less than two players in the game
  """
  def start_game(name), do: call_name(name, :start_game)

  @doc """
  Add a player to the current game. Only works if still in the lobby state.
  """
  def add_player(name, player), do: call_name(name, {:add_player, player})

  @doc """
  Remove a player from the current game. Only works if still in the lobby state.
  """
  def remove_player(name, player), do: call_name(name, {:remove_player, player})

  @doc """
  Get the state of the given server
  """
  def state(name), do: :sys.get_state(via(name))

  @doc """
  Submit either a description or an image for the current turn
  """
  @spec submit_turn(String.t(), Game.player(), any()) :: :ok | {:error, String.t()}
  def submit_turn(name, player, turn_data) do
    call_name(name, {:submit_turn, player, turn_data})
  end

  @spec get_prompt(String.t(), Game.player()) :: {:ok, any()} | {:error, String.t()}
  @doc """
  Get the current prompt for the given player
  """
  def get_prompt(name, player) do
    call_name(name, {:get_prompt, player})
  end
end
