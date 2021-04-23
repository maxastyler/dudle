defmodule Dudle.Game do
  @moduledoc """
  This module contains the implementation of the Dudle game logic. 

  A game is composed of a set of rounds. In each round, people first draw an image of 
  the prompt that's been described to them. Then the game alternates between writing a description
  and drawing the description of the previous player. The round finishes when a prompt reaches its player. 
  If there are N people in a round, there will be N turns. 
  """
  alias Dudle.Round

  @type player :: String.t()
  @type description :: String.t()
  @type drawing :: any()
  @type prompt_map :: %{player() => {String.t(), [{player(), description() | drawing()}]}}
  @type scores :: %{player() => {:correct | :favourite, player()}}

  @type round :: %{
          next_players: %{player() => player()},
          prompts: prompt_map(),
          scores: scores()
        }

  @type t() :: %__MODULE__{
          players: [player()],
          rounds: [round()]
        }

  @enforce_keys [:players]
  defstruct players: nil, rounds: []

  @prompts ["Prompt 1", "Stinky prompt", "An incredibly cool picture", "Very very cool"]

  @doc """
  Turn the list l into a map where each key maps to the next value in the list. 
  The last element of the list wraps to the first element.
  """
  @spec list_to_adjacency_map([t]) :: %{t => t}
  defp list_to_adjacency_map([first | rest] = l) do
    Enum.zip(l, rest ++ [first]) |> Map.new()
  end

  @doc """
  Given a Mapset of players, and a set of prompts to use for the game, construct the initial game state. 
  If there are less prompts than there are players, return an {:error, error} tuple
  Otherwise, return {:ok, round}
  """
  def new_game(players, prompts) do
    player_list = Enum.shuffle(players)

    with {:ok, round} <- Round.new_round(player_list, prompts) do
      {:ok,
       %{
         players: player_list,
         player_order: list_to_adjacency_map(player_list),
         prompts: prompts,
         round: round,
         previous_rounds: []
       }}
    else
      {:error, e} -> {:error, e}
    end
  end

  @doc """
  Get the current prompt for the given player
  """
  def get_prompt(%{round: %{prompts: prompts}} = _game, player) do
    prompts[player]
  end

  @doc """
  Add the map of submissions to the current game

  The submissions should be a map %{player => {submission_type, player_name, submission}}
  """
  def add_submissions(%{player_order: player_order} = game, submissions) do
    update_in(game, [:round, :submissions], fn subs ->
      for {p, s} <- subs, into: %{}, do: {p, [submissions[p] | s]}
    end)
    |> put_in(
      [:round, :prompts],
      for({p, s} <- submissions, into: %{}, do: {player_order[p], s})
    )
  end

  @doc """
  Is the current round complete?
  """
  def round_complete?(%{players: players, round: %{submissions: submissions}} = _game) do
    min_submission_size = for({_p, s} <- submissions, do: length(s)) |> Enum.min()
    min_submission_size >= length(players) + 1
  end
end
