defmodule DudleWeb.RevealComponent do
  use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("reveal_next", _v, socket), do: {:noreply, socket}
end
