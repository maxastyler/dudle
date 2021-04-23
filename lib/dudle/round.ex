defmodule Dudle.Round do
  @moduledoc """
  The type for a round of dudle

  An ongoing round needs to keep track of who's submitted stuff, and who needs to receive a submission
  """

  @type player() :: String.t()

  @type prompt_map() :: %{player() => {}}

  @doc """
  Create the player->prompts map for the given set of prompts and players
  """
  @spec pick_prompts([player()], [String.t()]) :: prompt_map()
  defp pick_prompts(players, prompts) do
    for {player, prompt} <- Enum.zip(players, Enum.take_random(prompts, length(players))), into: %{} do
      {player, {:text, "initial prompt", prompt}}
    end
  end

  def new_round(players, possible_prompts) do
    if length(possible_prompts) < length(players) do
      {:error, "Less prompts than there are players"}
    else
      prompts = pick_prompts(players, possible_prompts)
      round = %{
        submissions: (for {p, s} <- prompts, into: %{}, do: {p, [s]}),
        prompts: prompts,
      }
      {:ok, round}
    end
  end
end
