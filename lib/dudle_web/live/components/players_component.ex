defmodule DudleWeb.PlayersComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <h4>Players in room <b><%= @room %></b>:</h4>
    <%= for {player, data} <- Enum.sort(@players) do %>
    <%= live_component @socket, DudleWeb.PlayerComponent, id: player, data: data%>
    <hr class="solid">
    <% end %>
    """
  end
end
