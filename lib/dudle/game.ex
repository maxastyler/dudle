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

  @type round :: %{
          next_players: %{player() => player()},
          prompts: %{player() => {String.t(), [{player(), description | any()}]}}
        }

  @type t() :: %__MODULE__{
          players: [player()],
          rounds: [round()]
        }

  @enforce_keys [:players]
  defstruct players: nil, rounds: []

  @prompts ["Prompt 1", "Stinky prompt", "An incredibly cool picture", "Very very cool"]

  @spec new_round(t(), [description()]) :: {:ok, t()} | {:error, String.t()}
  def new_round(%Dudle.Game{rounds: rounds} = game, possible_prompts \\ @prompts) do
    if length(possible_prompts) < length(game.players) do
      {:error, "Less prompts than there are players"}
    else
      next_round = %{
        next_players: list_to_adjacency_map(game.players),
        prompts:
          for {p, d} <-
                Enum.zip(
                  game.players,
                  Enum.take_random(possible_prompts, length(game.players))
                ),
              into: %{} do
            {p, {d, []}}
          end
      }

      {:ok, %Dudle.Game{game | rounds: [next_round | rounds]}}
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
