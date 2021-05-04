defmodule Dudle.Prompt do
  @moduledoc """
  A prompt for Dudle
  """

  use TypedStruct

  typedstruct enforce: true do
    plugin TypedStructLens
    @typedoc "A prompt in Dudle"

    field :type, :image | :text
    field :submitter, String.t() | :initial
    field :data, String.t()
  end
end
