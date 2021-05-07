defmodule DudleWeb.VoteComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <%= if @is_main_player do %>
    <%= for player <- @votees do %>
    <button phx-click="submit_vote" phx-value-name="<%= player %>"><%= player %></button>
    <% end %>
    <% else %>
    <%= @player %> is voting
    <% end %>
    """
  end
end
