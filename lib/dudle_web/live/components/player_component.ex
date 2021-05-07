defmodule DudleWeb.PlayerComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    <%= @id %>
    Online: <%= @data[:online] %>
    <%= if @data[:score] do %>
    Score: <%= @data[:score] %>
    <% end %>
    <%= if Map.has_key?(@data, :submitted) do %>
    Submitted: <%= @data[:submitted] %>
    <% end %>
    """
  end
end
