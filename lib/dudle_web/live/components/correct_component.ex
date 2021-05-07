defmodule DudleWeb.CorrectComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    Are these prompts the same?:
    <%= live_component @socket, DudleWeb.PromptComponent, prompt: @first_prompt %>
    <%= live_component @socket, DudleWeb.PromptComponent, prompt: @last_prompt %>
    <%= if @is_main_player do %>
    <button phx-click="submit_correct" phx-value-correct="true">Yes</button>
    <button phx-click="submit_correct" phx-value-correct="false">No</button>
    <% end %>
    """
  end
end
