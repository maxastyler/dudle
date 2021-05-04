defmodule Dudle.Game do
  use TypedStruct

  alias Dudle.{Round, Prompt, Options}

  typedstruct enforce: true do
    plugin TypedStructLens
    @typedoc "A game of Dudle"

    field :rounds, [Round.t()]
    field :scores, %{String.t() => integer()}
    field :round_submissions, %{String.t() => [Prompt.t()]}
    field :turn_submissions, %{String.t() => Prompt.t()}
    field :prompts, MapSet.t(Prompt.t())
    field :players, [String.t()]
    field :player_adjacency, %{String.t() => String.t()}
    field :options, Options.t()
  end
end
