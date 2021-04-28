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
    for {player, prompt} <- Enum.zip(players, Enum.take_random(prompts, length(players))),
        into: %{} do
      {player, {:text, "initial prompt", prompt}}
    end
  end

  def new_round(players, possible_prompts) do
    if length(possible_prompts) < length(players) do
      {:error, "Less prompts than there are players"}
    else
      prompts = pick_prompts(players, possible_prompts)

      round = %{
        submissions: for({p, s} <- prompts, into: %{}, do: {p, [s]}),
        prompts: prompts
      }

      {:ok, round}
    end
  end

  defp mod(x, n) do
    x = rem(x, n)

    if x < 0 do
      x + n
    else
      x
    end
  end

  defp rotate(rs, 0), do: rs
  defp rotate([r | rs], n), do: rotate(List.insert_at(rs, -1, r), n - 1)
  defp rotate(r, n) when length(r) < 0 or length(r) >= n, do: rotate(r, mod(length(r), n))

  defp get_first_and_last_text_prompt(prompts, player) do
    texts = prompts[player] |> Enum.filter(&(elem(&1, 0) == :text))
    {List.first(texts), List.last(texts)}
  end

  @doc """
  Convert the round from a playing state into a reviewing state
  """
  def convert_to_reviewing_state(%{submissions: submissions} = round, players) do
    reversed = for {p, s} <- submissions, into: %{}, do: {p, Enum.reverse(s)}

    review =
      for [_, {_, player, _} | _] = v <-
            Enum.map(players, &reversed[&1])
            |> Enum.zip()
            |> Enum.zip([0 | Enum.to_list(0..length(players))])
            |> Enum.map(fn {l, i} -> rotate(Tuple.to_list(l), i) end)
            |> Enum.zip()
            |> Enum.map(&Tuple.to_list(&1)),
          into: %{} do
        {player, v}
      end

    round
    |> Map.drop([:submissions])
    |> Map.put(:prompts, review)
    |> Map.put(:review_state, {List.first(players), 0})
    |> Map.put(:reviewers_left, Enum.drop(players, 1))
  end

  @doc """
  Get the current prompt to review from the round
  """
  def get_review_prompt(%{review_state: {player, element}, prompts: prompts} = _round) do
    prompts[player] |> Enum.at(element)
  end

  @doc """
  Get the next review state of the round, returning :finished if done
  """
  def get_next_review_state(
        %{review_state: {player, element}, prompts: prompts, reviewers_left: reviewers} = round,
        players
      ) do
    case element do
      {:text_correct, _} ->
        Map.put(round, :review_state, {player, {:vote, Enum.filter(players, &(&1 != player))}})

      {:vote, _} ->
        with [r | rs] <- reviewers do
          Map.put(round, :review_state, {r, 0})
          |> Map.put(:reviewers_left, rs)
        else
          _ -> :finished
        end

      x when x >= map_size(prompts) ->
        Map.put(
          round,
          :review_state,
          {player, {:text_correct, get_first_and_last_text_prompt(prompts, player)}}
        )

      x ->
        Map.put(round, :review_state, {player, x + 1})
    end
  end
end
