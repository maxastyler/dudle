defmodule Dudle.GameServer do
  use GenStateMachine

  alias Dudle.Presence

  @server_timeout 10 * 60 * 1000

  def start_link(options) do
    {data, opts} = Keyword.pop(options, :data)
    GenStateMachine.start_link(__MODULE__, data, opts)
  end

  @impl true
  def init(%{room: room} = _data) do
    DudleWeb.Endpoint.subscribe("presence:#{room}")

    {:ok, :lobby, %{room: room, presence_players: [], game: nil},
     [{:timeout, @server_timeout, :any}]}
  end

  @impl true
  def handle_event(:timeout, _, _, _), do: {:stop, :shutdown}
end
