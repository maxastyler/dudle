defmodule DudleWeb.PlayersComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <%= for {player, data} <- Enum.sort(@players) do %>
    <%= live_component @socket, DudleWeb.PlayerComponent, id: player, data: data%>
    <% end %>
    """
  end
end
