defmodule Dudle.RoundTest do
  use ExUnit.Case

  alias Dudle.{Round, Prompt}

  test "round submissions are rotated correctly" do
    order = ["a", "b", "c", "d", "e", "f", "g"]
    order_cycle = Stream.cycle(order) |> Stream.drop(1)

    prompts =
      for {x, i} <- Enum.with_index(order), into: %{} do
        {x,
         Stream.drop(order_cycle, i)
         |> Enum.take(length(order))
         |> Enum.map(&Prompt.new(:text, x, &1))
         |> List.insert_at(-1, Prompt.new(:text, :initial, ""))}
      end

    [p1 | ls] = Map.to_list(prompts)
    prompts = Enum.reverse(ls) |> List.insert_at(-1, p1) |> Map.new()

    for {player, [_ | prompts]} <- Round.create_from_round_submissions(prompts, order).prompts do
      assert Enum.all?(prompts, &(&1.data == player))

      assert Enum.map(prompts, & &1.submitter)
             |> Enum.frequencies()
             |> Enum.all?(fn {_, n} -> n == 1 end)
    end
  end
end
