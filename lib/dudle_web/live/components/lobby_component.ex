defmodule DudleWeb.LobbyComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    <form phx-submit="start_game">
    <label for="max_score">Maximum score (set to 0 for no max score):</label>
    <input type="number" name="max_score" id="max_score" value=7 max=<%= Dudle.Options.max_score_limit() %> />
    <label for="max_rounds">Maximum number of rounds (set to 0 for no max rounds):</label>
    <input type="number" name="max_rounds" id="max_rounds" value=4 max=<%= Dudle.Options.max_rounds_limit() %> />
    <button type="submit">Start game</button>
    </form>
    """
  end
end
