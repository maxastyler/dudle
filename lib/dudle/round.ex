defmodule Dudle.Round do
  use TypedStruct

  alias Dudle.{Prompt}

  typedstruct enforce: true do
    plugin TypedStructLens
    @typedoc "A round of dudle"

    field :prompts, %{String.t() => [Prompt.t()]}
    field :results, %{String.t() => %{favourite: String.t(), correct: boolean()}}
  end

  defp mod(x, n) do
    x = rem(x, n)

    if x < 0 do
      x + n
    else
      x
    end
  end

  defp rotate(rs, 0), do: rs
  defp rotate([r | rs], n), do: rotate(List.insert_at(rs, -1, r), n - 1)
  defp rotate(r, n) when length(r) < 0 or length(r) >= n, do: rotate(r, mod(length(r), n))

  @doc """
  Create a round struct from the submissions for a given round
  """
  @spec create_from_round_submissions(%{String.t() => [Prompt.t()]}) :: __MODULE__.t()
  def create_from_round_submissions(round_submissions) do
    reversed = for {p, s} <- round_submissions, into: %{}, do: {p, Enum.reverse(s)}

    prompts =
      for [_, %Prompt{submitter: player} | _] = v <-
            Enum.map(Map.keys(round_submissions), &reversed[&1])
            |> Enum.zip()
            |> Enum.zip([0 | Enum.to_list(0..map_size(round_submissions))])
            |> Enum.map(fn {l, i} -> rotate(Tuple.to_list(l), i) end)
            |> Enum.zip()
            |> Enum.map(&Tuple.to_list(&1)),
          into: %{} do
        {player, v}
      end

    %__MODULE__{prompts: prompts, results: Map.keys(prompts) |> Enum.map(&{&1, %{}}) |> Map.new()}
  end
end
