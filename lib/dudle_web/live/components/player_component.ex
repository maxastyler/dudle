defmodule DudleWeb.PlayerComponent do
  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    ~L"""
    <div class="player <%= if @data[:online], do: "", else: "offline"%>">
    <p><%= @id %>
    <%= if @data[:score], do: ": #{@data[:score]}"%>
    <%= if Map.has_key?(@data, :submitted) and @data[:submitted] == true, do: " ✔"%></p>
    </div>
    """
  end
end
