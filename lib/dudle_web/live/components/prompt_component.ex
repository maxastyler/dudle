defmodule DudleWeb.PromptComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    <%= @prompt.type %>
    <%= @prompt.submitter %>
    <%= String.slice(@prompt.data, 0, 10) %>
    """
  end
end
