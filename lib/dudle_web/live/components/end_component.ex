defmodule DudleWeb.EndComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    You've finished the game!
    <button phx-click="reset_game">Restart?</button>
    """
  end
end
