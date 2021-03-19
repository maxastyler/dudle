defmodule Dudle.Game do
  @moduledoc """
  This module contains the implementation of the Dudle game logic. 

  A game is composed of a set of rounds. In each round, people first draw an image of 
  the prompt that's been described to them. Then the game alternates between writing a description
  and drawing the description of the previous player. The round finishes when a prompt reaches its player. 
  If there are N people in a round, there will be N turns. 
  """

  @type player :: String.t()
  @type description :: String.t()
  @type drawing :: any()
  @type prompt_map :: %{player() => {String.t(), [{player(), description() | drawing()}]}}
  @type scores :: %{player() => {:correct | :favourite, player()}}

  @type round :: %{
          next_players: %{player() => player()},
          prompts: prompt_map(),
          scores: scores(),
        }

  @type t() :: %__MODULE__{
          players: [player()],
          rounds: [round()]
        }

  @enforce_keys [:players]
  defstruct players: nil, rounds: []

  @prompts ["Prompt 1", "Stinky prompt", "An incredibly cool picture", "Very very cool"]

  @doc """
  Try to make a new round
  """
  @spec new_round([player()], [description()]) :: {:ok, t()} | {:error, String.t()}
  def new_round(players, possible_prompts \\ @prompts) do
    if length(possible_prompts) < length(players) do
      {:error, "Less prompts than there are players"}
    else
      round = %{
        next_players: list_to_adjacency_map(players),
        prompts: pick_prompts(players, possible_prompts)
      }
      {:ok, round}
    end
  end

  @doc """
  Create the player->prompts map for the given set of prompts and players
  """
  @spec pick_prompts([player()], [String.t()]) :: prompt_map()
  defp pick_prompts(players, prompts) do
    for {player, prompt} <- Enum.zip(players, Enum.take_random(prompts, length(players))),
        into: %{} do
      {player, {prompt, []}}
    end
  end

  @doc """
  Turn the list l into a map where each key maps to the next value in the list. 
  The last element of the list wraps to the first element.
  """
  @spec list_to_adjacency_map([t]) :: %{t => t}
  defp list_to_adjacency_map([first | rest] = l) do
    Enum.zip(l, rest ++ [first]) |> Map.new()
  end
end
