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
  defp rotate(r, n) when n < 0 or n >= length(r), do: rotate(r, mod(n, length(r)))
  defp rotate([r | rs], n), do: rotate(List.insert_at(rs, -1, r), n - 1)

  @doc """
  Twist the given list of lists
  """
  @spec twist_list([v], list(integer())) :: [v] when v: any()
  defp twist_list(list, twists) do
    Enum.zip(list)
    |> Enum.zip(twists)
    |> Enum.map(fn {l, t} -> Tuple.to_list(l) |> rotate(t) end)
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
  end

  @doc """
  Create a round struct from the submissions for a given round
  """
  @spec create_from_round_submissions(%{String.t() => [Prompt.t()]}, [String.t()]) ::
          __MODULE__.t()
  def create_from_round_submissions(round_submissions, player_order) do
    reversed = for {p, s} <- round_submissions, into: %{}, do: {p, Enum.reverse(s)}

    prompts =
      for [_, %Prompt{submitter: player} | _] = v <-
            Enum.map(player_order, &reversed[&1])
            |> twist_list([0 | Enum.to_list(0..map_size(round_submissions))]),
          into: %{} do
        {player, v}
      end

    %__MODULE__{prompts: prompts, results: Map.keys(prompts) |> Enum.map(&{&1, %{}}) |> Map.new()}
  end
end
