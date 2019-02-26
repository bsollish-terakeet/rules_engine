defmodule RulesEngine do
  @moduledoc """
  a Rules Engine that applies rules according to their natural order (which is priority by default).
  """

  alias RulesEngineParameters
  alias Rule
  alias RuleGroup

  @spec fire(RulesEngineParameters.t, [Rule.t], map) :: any()
  def fire(params, rules, facts) do
    sorted_rules = sort_rules(rules)
    pre_skip_rules = get_pre_skip_rules(params, sorted_rules, facts)

    # we still need to check for failed actions
    if params.skip_on_first_failed_rule do
      do_rules_until_failure(pre_skip_rules, facts)
    else
      do_rules(pre_skip_rules, facts)
    end
  end

def sort_rules(rules) do
  Map.to_list(rules) |> Keyword.values() |> Enum.sort(&(Map.get(&1, :priority) <= Map.get(&2, :priority)))
end

  @doc """
  to implement the "skip_on..." parameters, we need to do
  an Enum.take_while first, to get the rules that will happen BEFORE the skip,
  and then do an Enum.each (or similar) to process them
  """
  def get_pre_skip_rules(params, sorted_rules, facts) do
    Enum.reduce_while(sorted_rules, [], fn(rule, acc) ->
      if rule.priority < params.rule_priority_threshold do
        case {params.skip_on_first_applied_rule, params.skip_on_first_non_triggered_rule} do
          {true,  true } -> {:halt, acc ++ [rule]}      # always skip
          {false, false} -> {:cont, acc ++ [rule]}    # never skip
          {_,     true } -> if applies?(rule, facts) do {:cont, acc ++ [rule]} else {:halt, acc ++ [rule]} end
          {true,  _    } -> if applies?(rule, facts) do {:halt, acc ++ [rule]} else {:cont, acc ++ [rule]} end
        end
      else
        {:halt, acc}
      end
    end)
  end

  defp applies?(rule, facts) do
    case rule do
      %Rule{} -> rule_applies?(rule, facts)
      %RuleGroup{} -> rule_group_applies?(rule, facts)
      _ -> false
    end
  end

  defp rule_applies?(rule, facts) do
    rule.condition.(facts)
  end

  defp rule_group_applies?(rule_group, facts) do
    Enum.all?(rule_group.rules, fn(rule) -> rule.condition.(facts) end)
  end

  defp do_rules(rules, facts) do
    for rule <- rules do
      case rule do
        %Rule{} -> do_rule(rule, facts)
        %RuleGroup{} -> do_rule_group(rule, facts)
      end
    end
  end

  defp do_rule(rule, facts) do
    if rule.condition.(facts) do
      for func <- rule.actions do
        func.(facts)
      end
    end
  end

  defp do_rule_group(rule_group, facts) do
    case rule_group.type do
      :unit_rule_group -> do_unit_rule_group(rule_group, facts)
      :activation_rule_group -> do_activation_rule_group(rule_group, facts)
      :conditional_rule_group -> do_conditional_rule_group(rule_group, facts)
    end
  end

  # NOTE - UnitRuleGroup - a composite rule that acts as a unit:
  # Either all rules are applied or nothing is applied.
  defp do_unit_rule_group(rule_group, facts) do
    if rule_group_applies?(rule_group, facts) do
      sorted_rules = RuleGroup.get_sorted_rules(rule_group)
      do_rules(sorted_rules, facts)
    end
  end

  # NOTE - ActivationRuleGroup - a composite rule that fires
  # the first applicable rule and ignores other rules in the group (XOR logic).
  # Rules are first sorted by their natural order (priority by default) within the group.
  defp do_activation_rule_group(rule_group, facts) do
    sorted_rules = RuleGroup.get_sorted_rules(rule_group)

    Enum.reduce_while(sorted_rules, nil, fn(rule, _acc) ->
      if rule.condition.(facts) do
        do_rule(rule, facts)
        {:halt, rule}
      else
        {:cont, nil}
      end
    end)
  end

  # NOTE - ConditionalRuleGroup - a composite rule where the rule
  # with the highest priority acts as a condition: if the rule with the highest priority
  # evaluates to true, then the rest of the rules are fired.
  defp do_conditional_rule_group(rule_group, facts) do
    sorted_rules = RuleGroup.get_sorted_rules(rule_group)
    conditional_rule = hd(sorted_rules)

    if applies?(conditional_rule, facts) do
      if length(sorted_rules) > 1 do
        do_rules(tl(sorted_rules), facts)
      end
    end
  end

  defp do_rules_until_failure(rules, facts) do
    Enum.reduce_while(rules, true, fn(rule, _acc) ->
      case rule do
        %Rule{} -> do_rule_until_failure(rule, facts)
        %RuleGroup{} -> do_rules_until_failure(rule.rules, facts)
      end
    end)
  end

  defp do_rule_until_failure(rule, facts) do
    if rule.condition.(facts) do
      if all_actions_succeed?(rule, facts) do
        {:cont, true}
      else
        {:halt, false}
      end
    end
  end

  defp all_actions_succeed?(rule, facts) do
    Enum.reduce_while(rule.actions, true, fn(func, _acc) ->
      case func.(facts) do
        :ok -> {:cont, true}
        {:error, _} -> {:halt, false}
      end
    end)
  end
end
