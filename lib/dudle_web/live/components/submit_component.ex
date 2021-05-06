defmodule DudleWeb.SubmitComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    Submit component
    <%= live_component @socket, DudleWeb.PromptComponent, id: :submit_prompt, prompt: @prompt %>
    <%= case @prompt.type do %>
    <%= :text -> %>
    <div id="sketchpad" phx-update="ignore" phx-hook="SketchPad"></div>
    <%= :image -> %>
    <form phx-submit="handle_text_data">
    <input type="text" name="prompt_text" autocomplete="off" placeholder="Input your prompt text" value="<%= assigns[:text_data] %>" />
    <button type="submit">Submit</button>
    </form>
    <% end %>
    """
  end
end
