defmodule Dudle.GameSweeper do
  @moduledoc """
  This is a server which periodically 
  looks through the currently running games and closes ones with no people connected
  """
  use GenServer
  alias Dudle.GameClient

  @sweep_timeout 2 * 60 * 1000

  def start_link(options) do
    GenServer.start_link(__MODULE__, %{}, options)
  end

  defp schedule_sweep() do
    Process.send_after(self(), :sweep, @sweep_timeout)
  end

  @impl true
  def init(data) do
    schedule_sweep()
    {:ok, data}
  end

  @impl true
  def handle_info(:sweep, state) do
    for c <- DynamicSupervisor.which_children(Dudle.GameSupervisor) do
      case c do
        {_, :restarting, _, _} ->
          nil

        {_, pid, _, _} ->
          room = GameClient.get_room_name(pid)

          if map_size(Dudle.Presence.list("presence:#{room}")) == 0 do
            DynamicSupervisor.terminate_child(Dudle.GameSupervisor, pid)
          end
      end
    end

    schedule_sweep()
    {:noreply, state}
  end
end
