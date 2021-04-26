defmodule DudleWeb.PlayersComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <h3>Players:</h3>
    <%= for player <- @players do %>
    <h4><%= player %></h4>
    <% end %>
    """
  end
end
