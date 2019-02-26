defmodule RulesEngine.InferenceRulesEngine do
  @moduledoc """
  a Rules Engine that continuously applies rules on known facts until no more rules are applicable.
  """

  alias RulesEngine.{Rule, RulesEngineParameters}
  alias RulesEngine, as: RE

  @spec fire(RulesEngineParameters.t, [Rule.t], map) :: any()
  def fire(params, rules, facts) do
    sorted_rules = RE.sort_rules(rules)
    pre_skip_rules = RE.get_pre_skip_rules(params, sorted_rules, facts)

    if Enum.any?(pre_skip_rules, fn(rule) -> rule.condition.(facts) end) do
      RE.fire(params, rules, facts)
      fire(params, rules, facts)
    else
      :ok   # we reached the end - there are no more rules whose conditions are true
    end
  end

end
