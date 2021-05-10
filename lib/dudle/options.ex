defmodule Dudle.Options do
  use TypedStruct

  def max_score_limit, do: 200
  def max_rounds_limit, do: 30

  typedstruct do
    plugin TypedStructLens
    @typedoc "A set of options for a Dudle game"

    field :max_score, integer() | nil
    field :max_rounds, integer() | nil
    field :avoid_prompt_repetition, boolean(), default: false
  end

  def validate_options_from_web(max_score, max_rounds) do
    max_score = if is_binary(max_score), do: String.to_integer(max_score), else: max_score
    max_rounds = if is_binary(max_rounds), do: String.to_integer(max_rounds), else: max_rounds
    score_oob = max_score < 1 or max_score > max_score_limit()
    rounds_oob = max_rounds < 1 or max_rounds > max_rounds_limit()
    cond do
      score_oob and rounds_oob ->
        {:error, "At least one of max score and max rounds should be set"}

      score_oob ->
        {:ok, %__MODULE__{max_score: nil, max_rounds: max_rounds}}

      rounds_oob ->
        {:ok, %__MODULE__{max_score: max_score, max_rounds: nil}}

      :else ->
        {:ok, %__MODULE__{max_score: max_score, max_rounds: max_rounds}}
    end
  end

  def default() do
    %__MODULE__{max_score: nil, max_rounds: nil}
  end
end
