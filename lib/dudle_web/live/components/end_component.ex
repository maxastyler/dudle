defmodule DudleWeb.EndComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <div>
    <h3>Game finished!</h3>
    <button phx-click="reset_game">Restart?</button>
    </div>
    """
  end
end
