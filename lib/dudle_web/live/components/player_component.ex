defmodule DudleWeb.PlayerComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    <div class="card <%= if @data[:online], do: "", else: "offline"%>">
    <h4><%= @id %></h4>
    <%= if @data[:score] do %>
    <small>Score: <%= @data[:score] %></small>
    <% end %>
    <%= if Map.has_key?(@data, :submitted) do %>
    <small>Submitted: <%= @data[:submitted] %></small>
    <% end %>
    </div>
    """
  end
end
