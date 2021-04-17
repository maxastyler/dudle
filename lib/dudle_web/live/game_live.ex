defmodule DudleWeb.GameLive do
  use DudleWeb, :live_view
  alias Dudle.Presence
  alias Phoenix.LiveView.Socket

  @default_colour "#000000"

  @default_text_prompt {:text, "hi there"}
  @default_image_prompt {:image, "data:image/png;base64,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"}

  defp room_name_valid?(nil), do: false

  defp room_name_valid?(room_name) do
    String.length(room_name) > 0
  end

  defp name_valid?(nil), do: false

  defp name_valid?(name) do
    String.length(name) > 0
  end

  defp untrack_previous_name(room_name, name) do
    Presence.untrack(self(), "presence:#{room_name}", name)
  end

  defp track_name(%Socket{assigns: %{name: name}} = socket) do
    Presence.track(self(), presence_topic(socket), name, %{})
  end

  defp subscribe_to_room(socket) do
    DudleWeb.Endpoint.subscribe(presence_topic(socket))
    DudleWeb.Endpoint.subscribe(topic(socket))
  end

  defp add_room_name(socket, nil), do: {:error, "room name nil"}
  defp add_room_name(socket, room_name) do
    cond do
      not room_name_valid?(room_name) -> {:error, "room name invalid"}
      socket.assigns["room"] == nil ->
        DudleWeb.Endpoint.subscribe("presence:#{room_name}")
        DudleWeb.Endpoint.subscribe("game:#{room_name}")
        {:ok, assign(socket, "room", room_name)}
      socket.assigns["room"] == room_name -> {:ok, socket}
      :else -> {:error, "room name changed"}
    end
  end

  # subscribe to the given room or redirect
  defp subscribe_or_redirect(socket, room) do
    socket
  end

  defp presence_topic(%Socket{assigns: %{room: room}}), do: "presence:#{room}"

  defp topic(%Socket{assigns: %{room: room}}), do: "game:#{room}"

  # get the players in the room
  defp get_players(socket) do
    Presence.list(presence_topic(socket)) |> Map.keys()
  end

  # try subscribing to the given room's broadcast, erroring if the given player is already subscribed
  defp subscribe(player_name, socket) do
  end

  @impl true
  def mount(params, _session, socket) do
    if connected?(socket) do
      rv = room_name_valid?(params["room"])
      nv = name_valid?(params["name"])
      socket = if rv, do: assign(socket, room: params["room"]), else: socket
      socket = if nv, do: assign(socket, name: params["name"]), else: socket
      socket = if rv and nv do
        subscribe_to_room(socket)
        cond do
          params["name"] in get_players(socket) -> assign(socket, name_taken: true)
          :else ->
            track_name(socket)
            socket
        end
      else
        socket
      end
      IO.inspect(get_players(socket))
      {:ok, socket}
    else
      {:ok, socket}
    end
    
  end

  def handle_params(params, _session, socket) do
    # cond do
    #   room_name_valid?(params["room"]) and name_valid?(params["name"]) ->
    #     {:noreply, assign(socket, room: params["room"], name: params["name"])}
    #   :else -> {:noreply, socket}
    # end
    # with {:ok, socket} <- add_room_name(socket, params["room"]) do
    #   with {:ok, socket} <- add_name(socket, params["name"]) do
    #     IO.puts("name and room ok")
    #     {:noreply, socket}
    #   else
    #     {:error, "name nil"} ->
    #       IO.puts("The name was nil")
    #       {:noreply, socket}
    #     _ ->
    #       IO.puts("THE NAME WASn'T NIL")
    #       IO.inspect(params)
    #     {:noreply, push_redirect(socket, to: Routes.game_path(socket, :new, room: params["room"]))}
    #   end
    # else
    #   {:error, "room name invalid"} -> {:noreply, push_redirect(socket, to: Routes.game_path(socket, :new,
    #                                          (if params["name"] != nil, do: [name: params["name"]], else: [])))}
    #   _ -> {:noreply, socket}
    # end
    {:noreply, socket}
  end


  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    IO.inspect("PRESENCE DIFF")
    IO.inspect(payload)
    {:noreply, socket}
  end

  @impl true
  def handle_event("enter_room", %{"room" => room, "name" => name}, socket) do
    {:noreply,
    push_redirect(socket, to: Routes.game_path(socket, :new, room: room, name: name))}
  end

  @impl true
  def handle_event("change_name", %{"name" => name}, socket) do
    params = case socket.assigns["room"] do
      nil -> [name: name]
      r -> [room: nil, name: name]
    end
    {:noreply,
    push_redirect(socket, to: Routes.game_path(socket, :new, params))}
  end

  @impl true
  def handle_event("handle_sketch_data", %{"sketch_data" => sketch_data}, socket) do
    {:noreply, assign(socket, sketch_data: sketch_data)}
  end

  def handle_event("handle_image_data", %{"image_data" => image_data}, socket) do
    {:noreply, assign(socket, image_data: image_data)}
  end

  def handle_event("handle_text_data", data, socket) do
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
end
