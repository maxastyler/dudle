defmodule DudleWeb.LobbyComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    <button phx-click="start_game">Start game</button>
    """
  end
end
