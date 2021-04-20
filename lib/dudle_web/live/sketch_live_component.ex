defmodule DudleWeb.SketchLiveComponent do
  use Phoenix.LiveComponent

  @impl true
  def update(assigns, socket) do
    IO.puts(assigns[:colour])
    {:ok, socket
    |> push_event("change_colour", %{colour: assigns[:colour]})
     |> push_event("line_size", %{size: assigns[:size]})
     |> assign(Map.to_list(assigns))}
  end

  @impl true
  def handle_event("change-colour", %{"colour" => colour}, socket) do
    send(self(), {:change_colour, colour})
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("change-size", %{"size" => size}, socket) do
    send(self(), {:change_size, size})
    {:noreply, socket}
  end
end
