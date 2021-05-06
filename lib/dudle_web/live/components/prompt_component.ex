defmodule DudleWeb.PromptComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    <%= @prompt.type %>
    <%= @prompt.submitter %>
    <%= case @prompt.type do %>
    <%= :text -> %> <p>@prompt.data</p>
    <%= :image -> %> <img src=<%= @prompt.data %>></img>
    <% end %>
    """
  end
end
