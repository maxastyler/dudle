defmodule Dudle.OptionsTest do
  use ExUnit.Case

  alias Dudle.Options

  test "Can't create invalid options" do
    assert {:error, _} = Options.validate_options_from_web(0, 0)

    assert {:error, _} =
             Options.validate_options_from_web(
               Options.max_score_limit() + 1,
               Options.max_rounds_limit() + 1
             )
  end

  test "Creates valid options with correct input" do
    assert {:ok, %Options{}} = Options.validate_options_from_web(0, 1)
    assert {:ok, %Options{}} = Options.validate_options_from_web(1, 0)
    assert {:ok, %Options{}} = Options.validate_options_from_web(1, 1)

    assert {:ok, %Options{}} =
             Options.validate_options_from_web(1, Options.max_rounds_limit() + 1)

    assert {:ok, %Options{}} =
             Options.validate_options_from_web(
               Options.max_score_limit() + 1,
               Options.max_rounds_limit()
             )
  end
end
