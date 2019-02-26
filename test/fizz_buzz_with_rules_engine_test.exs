defmodule FizzBuzzWithRulesEngineTest do
  use ExUnit.Case

  alias FizzBuzzExample.FizzBuzzWithRulesEngine, as: FBRE

  test "fizz buzz with rules engine" do
    FBRE.main()

    assert 1 == 1
  end
end
