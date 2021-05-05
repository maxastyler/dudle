defmodule Dudle.Game do
  use TypedStruct

  alias Dudle.{Round, Prompt, Options}
  alias Dudle.Game.Prompts

  typedstruct enforce: true do
    plugin TypedStructLens
    @typedoc "A game of Dudle"

    field :rounds, [Round.t()], default: []
    field :scores, %{String.t() => integer()}
    field :round_submissions, %{String.t() => [Prompt.t()]}, default: %{}
    field :turn_submissions, %{String.t() => Prompt.t()}, default: %{}
    field :prompts, MapSet.t(Prompt.t())
    field :players, [String.t()]
    field :player_adjacency, %{String.t() => String.t()}
    field :options, Options.t()
  end

  @doc """
  Construct a new game from the given players, optionally setting the prompts and the options
  Errors if there are too few prompts for the number of players, or less than two players
  """
  @spec new(MapSet.t(String.t()), [String.t()], Options.t()) ::
          {:ok, __MODULE__.t()} | {:error, String.t()}
  def new(players, prompts \\ Prompts.prompts(), options \\ %Options{}) do
    cond do
      length(prompts) < MapSet.size(players) ->
        {:error, "less prompts than there are players"}

      MapSet.size(players) < 2 ->
        {:error, "less than two players"}

      :else ->
        [h | t] = player_list = Enum.shuffle(players)
        player_adjacency = Enum.zip(player_list, List.insert_at(t, -1, h)) |> Map.new()

        {:ok,
         %__MODULE__{
           options: options,
           player_adjacency: player_adjacency,
           players: player_list,
           prompts: prompts,
           scores: for(p <- player_list, into: %{}, do: {p, 0})
         }}
    end
  end
end
