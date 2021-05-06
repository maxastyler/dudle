defmodule DudleWeb.PlayerComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    <%= @id %>
    """
  end
end
