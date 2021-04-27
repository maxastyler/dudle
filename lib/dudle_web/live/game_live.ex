defmodule DudleWeb.GameLive do
  use DudleWeb, :live_view
  alias Dudle.Presence
  alias Phoenix.LiveView.Socket
  alias Dudle.GameClient
  alias Dudle.GameServer

  @default_colour "#000000"

  @maximum_room_name_length 100
  @maximum_name_length 50
  @maximum_text_prompt_length 200

  defp room_name_valid?(nil), do: false

  defp room_name_valid?(room_name) do
    len = String.length(room_name)
    len > 0 and len < @maximum_room_name_length
  end

  defp name_valid?(nil), do: false

  defp name_valid?(name) do
    len = String.length(name)
    len > 0 and len < @maximum_name_length
  end

  defp track_name(%Socket{assigns: %{name: name}} = socket) do
    Presence.track(self(), presence_topic(socket), name, %{})
  end

  defp subscribe_to_room(socket) do
    DudleWeb.Endpoint.subscribe(topic(socket))
  end

  defp presence_topic(%Socket{assigns: %{room: room}}), do: "presence:#{room}"

  defp topic(%Socket{assigns: %{room: room}}), do: "game:#{room}"

  # get the players in the room
  defp get_players(socket) do
    Presence.list(presence_topic(socket)) |> Map.keys() |> Enum.sort()
  end

  defp get_state(socket) do
    case GameClient.get_state(socket.assigns.room, socket.assigns.name) do
      {:lobby, _} ->
        assign(socket, state: :lobby)

      {{:playing, :submitting} = state, data} ->
        assign(socket, state: state, prompt: data, text_data: "", submitted: false)

      {{:playing, :reviewing} = state, review_state, review_prompt} ->
        # TODO: refactor this into a function (cause it's used in two places)
        assign(socket,
          state: state,
          reset_review_state: true,
          review_state: review_state,
          review_data: [{review_state, review_prompt}]
        )
    end
  end

  defp join_room_with_name(room, name, socket) do
    rv = room_name_valid?(room)
    nv = name_valid?(name)
    if rv, do: GameClient.ensure_server_started(room)

    socket =
      if rv,
        do: assign(socket, room: room),
        else:
          put_flash(
            socket,
            :error,
            "Room name invalid (must be between 1 and #{@maximum_room_name_length} characters)"
          )

    socket =
      if nv,
        do: assign(socket, name: name),
        else:
          put_flash(
            socket,
            :error,
            "Player name invalid (must be between 1 and #{@maximum_name_length} characters)"
          )

    socket =
      if rv and nv do
        subscribe_to_room(socket)

        cond do
          name in get_players(socket) ->
            assign(socket, name_taken: true)

          :else ->
            track_name(socket)
            assign(socket, name_taken: false)
        end
      else
        socket
      end

    # if the room value is valid, get the players for the socket
    # socket = if rv, do: assign(socket, players: get_players(socket)), else: socket
    if rv and nv, do: get_state(socket), else: socket
  end

  @impl true
  @doc """
  The assigns that will exist in the socket are:
  :state - The current state of the game
  :room - The room the socket's in (this can be nil)
  :name_taken
  :name - The name of the current player (this can be nil too)
  :data - The data associated with the current state
  :prompt - The current prompt
  :review_data - the data to review
  """
  def mount(params, _session, socket) do
    socket = assign(socket, players: [])

    if connected?(socket) do
      socket = assign(socket, state: :joining)
      socket = join_room_with_name(params["room"], params["name"], socket)
      {:ok, socket, temporary_assigns: [review_data: []]}
    else
      {:ok, assign(socket, state: :mounting)}
    end
  end

  @impl true
  def handle_info(%{event: "data_update", payload: :data_update}, socket) do
    {:noreply, get_state(socket)}
  end

  def handle_info(
        %{event: "review_update", payload: {{_, review_element} = review_state, prompt}},
        socket
      ) do
    {:noreply,
     assign(socket,
       review_data: [{review_state, prompt}],
       review_state: review_state,
       reset_review_state: review_element == 0,
       state: {:playing, :reviewing}
     )}
  end

  def handle_info(
        %{event: "player_update", payload: players},
        socket
      ) do
    {:noreply, assign(socket, players: players)}
  end

  @impl true
  def handle_event("enter_room", %{"room" => room, "name" => name}, socket) do
    {:noreply, push_redirect(socket, to: Routes.game_path(socket, :new, room: room, name: name))}
  end

  @impl true
  def handle_event("handle_sketch_data", %{"sketch_data" => sketch_data}, socket) do
    {:noreply, assign(socket, sketch_data: sketch_data)}
  end

  def handle_event("handle_image_data", %{"image_data" => image_data}, socket) do
    GameClient.submit_image(socket.assigns.room, socket.assigns.name, image_data)
    {:noreply, assign(socket, image_data: image_data, submitted: true)}
  end

  def handle_event("handle_text_data", %{"prompt_text" => data} = _data, socket) do
    {text, socket} =
      if String.length(data) > @maximum_text_prompt_length do
        {String.slice(data, 0, @maximum_text_prompt_length),
         put_flash(
           socket,
           :info,
           "String length shortened to #{@maximum_text_prompt_length} characters"
         )}
      else
        {data, socket}
      end

    GameClient.submit_text(socket.assigns.room, socket.assigns.name, text)
    {:noreply, assign(socket, text_data: text, submitted: true)}
  end

  def handle_event("start_game", _, socket) do
    GameClient.start_game(socket.assigns.room)
    {:noreply, socket}
  end

  def handle_event("send_sketch_data", _, socket) do
    with %{sketch_data: sketch_data} <- socket.assigns do
      {:noreply, push_event(socket, "update_data", %{data: sketch_data})}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("get_image", _, socket) do
    {:noreply, push_event(socket, "send_image", %{})}
  end

  def handle_event("next_review_state", _, socket) do
    GameClient.reveal_next(socket.assigns.room)
    {:noreply, socket}
  end
end
