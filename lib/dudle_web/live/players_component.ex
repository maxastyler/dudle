defmodule DudleWeb.PlayersComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <h3>Players:</h3>
    <%= for {player_name, player_data} <- @players do %>
    <h4 style="<%= if @state == :lobby or player_data[:online], do: "color:black", else: "color:grey" %>">
<%= player_name %></h4>
<h5><%= if @state == {:playing, :submitting}, do: "Submitted: #{player_data[:submitted] == true}"%></h5>
    <% end %>
    """
  end
end
