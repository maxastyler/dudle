defmodule DudleWeb.SubmitComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    <%= case @prompt.type do %>
    <%= :text -> %>
    <h3>Draw this prompt:</h3>    
    <%= live_component @socket, DudleWeb.PromptComponent, id: :submit_prompt, prompt: @prompt %>
    <h3>Here:</h3>
    <div id="sketchpad" phx-update="ignore" phx-hook="SketchPad"></div>
    <%= :image -> %>
    <form phx-submit="handle_text_data">
    <label for="prompt_text">What does this image show?:</label>
    <%= live_component @socket, DudleWeb.PromptComponent, id: :submit_prompt, prompt: @prompt %>
    <input type="text" name="prompt_text" id="prompt_text" autocomplete="off" placeholder="Input your prompt text" value="<%= assigns[:text_data] %>" />
    <button type="submit">Submit</button>
    </form>
    <% end %>
    """
  end
end
