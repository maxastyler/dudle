defmodule DudleWeb.GameLive do
  @moduledoc """
  The main liveview for playing dudle
  """

  use DudleWeb, :live_view
  alias Dudle.GameClient
  alias DudleWeb.Endpoint
  alias Dudle.Presence

  defp via(room) do
    {:via, Registry, {Dudle.GameRegistry, room}}
  end

  defp get_state(socket) do
    # GameClient.get_state(via(socket.assigns.room))
    socket
  end

  defp get_players(socket) do
    socket
  end

  @impl true
  def mount(%{"room" => room, "name" => name} = _params, _session, socket) do
    socket =
      with {:ok, _} <- GameClient.start_server(room),
           {:ok, player} <- GameClient.join_game(via(room), name) do
        Endpoint.subscribe("game:#{room}")
        Presence.track(socket, name, %{})
        assign(socket, connected: true) |> get_state() |> get_players()
      else
        {:error, error_string} -> put_flash(socket, :error, error_string)
      end
      |> assign(room: room, name: name)

    {:ok, socket, temporary_assigns: [review_prompts: []]}
  end

  def mount(params, _session, socket) do
    {:ok, assign(socket, room: params["room"], name: params["name"])}
  end
end
