defmodule Dudle.GameServer do
  use GenStateMachine

  @impl true
  def start_link() do
    GenStateMachine.start_link()
  end

end
