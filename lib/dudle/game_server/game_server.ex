defmodule Dudle.GameServer do
  use GenStateMachine

  alias Dudle.Presence
  import Dudle.GameServer.Events

  @server_timeout 10 * 60 * 1000

  def start_link(options) do
    {data, opts} = Keyword.pop(options, :data)
    GenStateMachine.start_link(__MODULE__, data, opts)
  end

  @impl true
  def init(%{room: room} = _data) do
    DudleWeb.Endpoint.subscribe("presence:#{room}")
    players = presence_players(room)

    {:ok, :lobby, %{room: room, presence_players: players, game: nil},
     [{:timeout, @server_timeout, :any}]}
  end

  @impl true
  def handle_event(:timeout, _, _, _), do: {:stop, :shutdown}

  def handle_event(:info, %{event: "presence_diff"}, _state, data) do
    presence_diff(data)
  end

  def handle_event(:internal, :broadcast_players, state, data) do
    broadcast_players(state, data)
  end

  def handle_event({:call, from}, :start_game, state, data) do
    start_game(from, state, data)
  end
end
