defmodule DudleWeb.PromptComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    <div class="card">
    <%= case @prompt.type do %>
    <%= :text -> %> <h3><%= @prompt.data %></h3>
    <%= :image -> %> <img src=<%= @prompt.data %>></img>
    <% end %>
    <%= if @prompt.submitter == :initial do %>
    <p>Initial prompt</p>
    <% else %>
    <p>by: <%= @prompt.submitter %></p>
    <% end %>
    </div>
    """
  end
end
