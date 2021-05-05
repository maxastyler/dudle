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

  @doc """
  Create a new prompt
  """
  def new(type, submitter, data), do: %__MODULE__{type: type, submitter: submitter, data: data}
end
