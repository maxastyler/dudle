defmodule DudleWeb.LoginComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    <form phx-submit="enter_room">
    <label for="room">Room:</label>
        <input type="text" name="room" id="room" autocomplete="off" placeholder="Enter room name" value="<%= @room %>" />
        <label for="name">Player name:</label>
        <input type="text" name="name" id="name" autocomplete="off" placeholder="Enter player name" value="<%= @name %>" />
        <button type="submit">Go</button>
    </form>
    """
  end
end
