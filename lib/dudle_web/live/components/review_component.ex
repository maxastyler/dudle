defmodule DudleWeb.ReviewComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    Reviewing
    <%= if elem(@state, 0) == :review and get_in(@state, [Access.elem(1), Access.elem(0), Access.elem(0)]) == @name do %>
    <button phx-click="advance_review_state">Next prompt</button>
    <% end %>
    <div id="review_prompts" phx-update="<%= if elem(@state, 0) == :review and get_in(@state, [Access.elem(1), Access.elem(0), Access.elem(1)]) == 0, do: "replace", else: "prepend" %>">
    <%= for prompt_tuple <- @review_prompts do %>
    <%= live_component @socket, DudleWeb.PromptComponent, id: elem(prompt_tuple, 0), prompt: elem(prompt_tuple, 1) %>
    <% end %>
    </div>
    """
  end
end
