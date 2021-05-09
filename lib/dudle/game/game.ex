defmodule Dudle.Game do
  use TypedStruct

  alias Dudle.{Round, Prompt, Options}
  alias Dudle.Game.Prompts

  typedstruct enforce: true do
    plugin TypedStructLens
    @typedoc "A game of Dudle"

    field :rounds, [Round.t()], default: []
    field :scores, %{String.t() => integer()}
    field :round_submissions, %{String.t() => [Prompt.t()]}
    field :turn_submissions, %{String.t() => Prompt.t()}, default: %{}
    field :player_prompts, %{String.t() => Prompt.t()}
    field :prompts, MapSet.t(Prompt.t())
    field :players, [String.t()]
    field :player_adjacency, %{String.t() => String.t()}
    field :options, Options.t()
  end

  defp deal_prompts(players, prompts) do
    Enum.zip(
      players,
      Enum.take_random(prompts, length(players))
      |> Enum.map(&Prompt.new(:text, :initial, &1))
    )
    |> Map.new()
  end

  @doc """
  Construct a new game from the given players, optionally setting the prompts and the options
  Errors if there are too few prompts for the number of players, or less than two players
  """
  @spec new(MapSet.t(String.t()), MapSet.t(String.t()), Options.t()) ::
          {:ok, __MODULE__.t()} | {:error, String.t()}
  def new(players, prompts, options) do
    cond do
      MapSet.size(prompts) < MapSet.size(players) ->
        {:error, "Can't start game: there are less prompts than there are players"}

      MapSet.size(players) < 2 ->
        {:error, "Can't start game: there are less than two players"}

      :else ->
        [h | t] = player_list = Enum.shuffle(players)
        player_adjacency = Enum.zip(player_list, List.insert_at(t, -1, h)) |> Map.new()

        player_prompts = deal_prompts(player_list, prompts)

        {:ok,
         %__MODULE__{
           options: options,
           player_adjacency: player_adjacency,
           players: player_list,
           player_prompts: player_prompts,
           round_submissions:
             for({player, prompt} <- player_prompts, into: %{}, do: {player, [prompt]}),
           prompts: prompts,
           scores: for(p <- player_list, into: %{}, do: {p, 0})
         }}
    end
  end

  @doc """
  Reset the game to new round status
  """
  @spec new_round(__MODULE__.t()) :: __MODULE__.t()
  def new_round(%{players: players, prompts: prompts} = game) do
    new_prompts = deal_prompts(players, prompts)

    new_round_submissions =
      for({player, prompt} <- new_prompts, into: %{}, do: {player, [prompt]})

    game
    |> put_in([round_submissions], new_round_submissions)
    |> put_in([turn_submissions], %{})
    |> put_in([player_prompts], new_prompts)
  end

  @doc """
  Put the round submissions into the rounds list
  """
  def put_submissions_into_rounds(%{round_submissions: round_submissions} = game) do
    update_in(game, [rounds], &[Round.create_from_round_submissions(round_submissions) | &1])
  end
end
