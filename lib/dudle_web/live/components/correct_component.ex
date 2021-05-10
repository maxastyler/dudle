defmodule DudleWeb.CorrectComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <div>
    Are these prompts the same?:
    <%= live_component @socket, DudleWeb.PromptComponent, prompt: @first_prompt %>
    <%= live_component @socket, DudleWeb.PromptComponent, prompt: @last_prompt %>
    <%= if @is_main_player do %>
    <div class="button_container">
    <button phx-click="submit_correct" phx-value-correct="true">Yes</button>
    <button phx-click="submit_correct" phx-value-correct="false">No</button>
    </div>
    <% end %>
    </div>
    """
  end
end
