defmodule Dudle.GameServer do
  use GenStateMachine

  @server_timeout 10*60*1000

  def start_link(options) do
    {data, opts} = Keyword.pop(options, :data)
    GenStateMachine.start_link(__MODULE__, data, opts)
  end

  @impl true
  def init(%{room: room} = data) do
    DudleWeb.Endpoint.subscribe("presence:#{room}")
    {:ok, :lobby, data, [{:timeout, @server_timeout, :any}]}
  end

end
