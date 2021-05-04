defmodule Dudle.Options do
  use TypedStruct

  typedstruct do
    plugin TypedStructLens
    @typedoc "A set of options for a Dudle game"

    field :max_score, integer() | nil
    field :max_rounds, integer() | nil
    field :avoid_prompt_repetition, boolean(), default: false
  end
end
