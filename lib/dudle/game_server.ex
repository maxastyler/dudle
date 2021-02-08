defmodule Dudle.GameServer do
  use GenServer

  alias Dudle.Game
  import Access, only: [key: 1, key: 2, at: 1]

  def start_link(options) do
    {data, opts} = Keyword.pop(options, :data)
    GenServer.start_link(__MODULE__, {:lobby, data}, opts)
  end

  @impl true
  def init(state), do: {:ok, state}

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

  @impl true
  def handle_call(:start_game, _from, {:lobby, data}) do
    if MapSet.size(data.players) > 1 do
      game = %Game{players: MapSet.to_list(data.players) |> Enum.sort()} |> Game.new_round()
      {:reply, {:ok, nil}, {:in_game, %{game: game}}}
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
end
