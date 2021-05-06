defmodule DudleWeb.LoginComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    <form phx-submit="enter_room">
        <input type="text" name="room" placeholder="Enter room name" value="<%= @room %>" />
        <input type="text" name="name" placeholder="Enter player name" value="<%= @name %>" />
        <button type="submit">Go</button>
    </form>
    """
  end
end
