defmodule DudleWeb.GameLive do
  @moduledoc """
  The main liveview for playing dudle
  """

  use DudleWeb, :live_view
  alias Dudle.GameClient
  alias DudleWeb.Endpoint

  defp via(room) do
    {:via, Registry, {Dudle.GameRegistry, room}}
  end

  defp get_state(socket) do
    GameClient.get_state(via(socket.assigns.room))
  end

  @impl true
  def mount(%{"room" => room, "name" => name} = _params, _session, socket) do
    with {:ok, _} <- GameClient.start_server(room),
         {:ok, player} <- GameClient.join_game(via(room), name) do
      Endpoint.subscribe("game:#{room}")
      assign(asocket, room: room, name: name, connected: true)
    else
      {:error, error_string} -> put_flash(socket, :error, error_string)
    end
  end

  def mount(params, _session, socket) do
  end
end
