defmodule DudleWeb.VoteComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <div>
    <%= if @is_main_player do %>
    <h3>Who's submission was your favourite?:</h3>
    <div class="button_container">
    <%= for player <- @votees do %>
    <button phx-click="submit_vote" phx-value-name="<%= player %>"><%= player %></button>
    <% end %>
    </div>
    <% else %>
    <h3><%= @player %> is voting</h3>
    <% end %>
    </div>
    """
  end
end
