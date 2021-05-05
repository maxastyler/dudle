defmodule Dudle.Round do
  use TypedStruct

  alias Dudle.Submission

  typedstruct enforce: true  do
    plugin TypedStructLens
    @typedoc "A round of dudle"

    field :prompts, %{String.t() => [Submission.t()]}
    field :results, %{String.t() => %{favourite: String.t(), correct: boolean()}}
  end

  def from_round_submissions(round_submissions) do
    
  end
end
