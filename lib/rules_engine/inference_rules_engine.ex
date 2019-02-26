defmodule RulesEngine.InferenceRulesEngine do
  @moduledoc """
  a Rules Engine that continuously applies rules on known facts until no more rules are applicable.
  """

  use RulesEngine

  @doc """
  fires the inference rules engine, which will continue to be called repeatedly
  as long as any of the rules' conditions are true
  """
  def inference_fire(params, rules, facts) do
    sorted_rules = sort_rules(rules)
    pre_skip_rules = get_pre_skip_rules(params, sorted_rules, facts)

    if Enum.any?(pre_skip_rules, fn(rule) -> rule.condition.(facts) end) do
      fire(params, rules, facts)
      inference_fire(params, rules, facts)
    else
      :ok   # we reached the end - there are no more rules whose conditions are true
    end
  end

end
