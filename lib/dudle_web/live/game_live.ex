defmodule DudleWeb.GameLive do
  @moduledoc """
  The main liveview for playing dudle
  """

  use DudleWeb, :live_view
  alias Dudle.GameClient
  alias DudleWeb.Endpoint
  alias Dudle.{Presence, Prompt}

  defp via(room) do
    {:via, Registry, {Dudle.GameRegistry, room}}
  end

  defp assign_state(socket, {:review, {{_, element}, prompt}} = state) do
    assign(socket, state: state)
    |> update(:review_prompts, &[{element, prompt} | &1])
  end

  defp assign_state(socket, state) do
    assign(socket, state: state)
  end

  defp get_state(socket) do
    assign_state(socket, GameClient.get_state(via(socket.assigns.room), socket.assigns.name))
  end

  defp assign_players(socket, players) do
    assign(socket, players: players)
  end

  defp get_players(socket) do
    assign_players(socket, GameClient.get_players(via(socket.assigns.room)))
  end

  defp handle_prompt_submission(prompt_type, prompt_data, socket) do
    with :ok <-
           GameClient.submit_prompt(
             via(socket.assigns.room),
             Prompt.new(prompt_type, socket.assigns.name, prompt_data)
           ) do
      put_flash(socket, :info, "submitted")
    else
      {:error, e} -> put_flash(socket, :error, e)
    end
  end

  @impl true
  def mount(%{"room" => room, "name" => name} = _params, _session, socket) do
    if connected?(socket) do
      socket = assign(socket, room: room, name: name, review_prompts: [])

      socket =
        with {:ok, _} <- GameClient.start_server(room),
             {:ok, _player} <- GameClient.join_game(via(room), name) do
          Endpoint.subscribe("game:#{room}")
          Presence.track(self(), "presence:#{room}", name, %{})
          get_state(socket) |> get_players() |> assign(connected: true)
        else
          {:error, error_string} -> put_flash(socket, :error, error_string)
        end

      {:ok, socket, temporary_assigns: [review_prompts: []]}
    else
      {:ok, assign(socket, room: room, name: name)}
    end
  end

  def mount(params, _session, socket) do
    {:ok, assign(socket, room: params["room"], name: params["name"])}
  end

  @impl true
  def handle_info(%{event: "broadcast_players", payload: player_state}, socket) do
    {:noreply, assign_players(socket, player_state)}
  end

  def handle_info(%{event: "broadcast_state", payload: :state_updated}, socket) do
    {:noreply, get_state(socket)}
  end

  def handle_info(%{event: "broadcast_state", payload: game_state}, socket) do
    {:noreply, assign_state(socket, game_state)}
  end

  @impl true
  def handle_event("enter_room", %{"room" => room, "name" => name}, socket) do
    {:noreply,
     push_redirect(socket, to: Routes.game_path(socket, :index, room: room, name: name))}
  end

  def handle_event("start_game", _, socket) do
    with {:ok, _} <- GameClient.start_game(via(socket.assigns.room)) do
      {:noreply, socket}
    else
      {:error, e} -> {:noreply, put_flash(socket, :error, e)}
    end
  end

  def handle_event("handle_text_data", %{"prompt_text" => prompt_text}, socket) do
    {:noreply, handle_prompt_submission(:text, prompt_text, socket)}
  end

  def handle_event("handle_image_data", %{"image_data" => image_data}, socket) do
    {:noreply, handle_prompt_submission(:image, image_data, socket)}
  end

  def handle_event("advance_review_state", _, socket) do
    GameClient.advance_review_state(via(socket.assigns.room), socket.assigns.name)
    {:noreply, socket}
  end

  def handle_event("submit_correct", %{"correct" => value}, socket) do
    GameClient.submit_correct(via(socket.assigns.room), socket.assigns.name, value == "true")
    {:noreply, socket}
  end

  def handle_event("submit_vote", %{"name" => value}, socket) do
    GameClient.submit_vote(via(socket.assigns.room), socket.assigns.name, value)
    {:noreply, socket}
  end
end
