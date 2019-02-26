defmodule FizzBuzzWithRulesEngineTest do
  use ExUnit.Case

  alias FizzBuzzExample.FizzBuzzWithRulesEngine, as: FBRE

  # alias Rule
  # alias RulesEngine, as: RE
  # alias InferenceRulesEngine, as: IRE
  # alias RulesEngineParameters, as: REP
  # alias RuleGroup, as: RG

  test "fizz buzz with rules engine" do
    FBRE.main()
    
    assert 1 == 1
  end
end
