defmodule DudleWeb.PromptComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    <div>
    <%= case @prompt.type do %>
    <%= :text -> %> <p><%= @prompt.data %></p>
    <%= :image -> %> <img src=<%= @prompt.data %>></img>
    <% end %>
    <h5><%= @prompt.submitter %></h5>
    </div>
    """
  end
end
