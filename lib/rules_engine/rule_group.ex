defmodule RulesEngine.RuleGroup do
  @moduledoc """
  UnitRuleGroup: A unit rule group is a composite rule that acts as a unit:
  Either all rules are applied or nothing is applied.

  ActivationRuleGroup: An activation rule group is a composite rule that fires
  the first applicable rule and ignores other rules in the group (XOR logic).
  Rules are first sorted by their natural order (priority by default) within the group.

  ConditionalRuleGroup: A conditional rule group is a composite rule where the rule
  with the highest priority acts as a condition: if the rule with the highest priority
  evaluates to true, then the rest of the rules are fired.
  """

  alias __MODULE__

  @types [:unit_rule_group, :activation_rule_group, :conditional_rule_group]

  alias RulesEngine.Rule

  defstruct name: "",
            description: "",
            priority: 0,
            type: nil,
            rules: []

  @type t :: %RuleGroup{
          name: String.t(),
          description: String.t(),
          priority: non_neg_integer(),
          type: atom(),
          rules: [Rule.t()]
        }

  alias __MODULE__

  @spec create(map) :: RuleGroup.t()
  def create(%{type: type, rules: rules} = _params) when type in @types do
    rule_group = Map.merge(%RuleGroup{}, %{type: type})
    add_rules(rule_group, rules)
  end

  def create(%{type: type} = params) when type in @types do
    Map.merge(%RuleGroup{}, params)
  end

  @spec create(atom, [Rule.t]) :: RuleGroup.t()
  def create(type, rules \\ []) when type in @types do
    Map.merge(%RuleGroup{}, %{type: type, rules: rules})
  end

  @spec add_rule(RuleGroup.t(), Rule.t()) :: RuleGroup.t()
  def add_rule(rule_group, %Rule{} = rule) do
    %{rule_group | rules: rule_group.rules ++ [rule]}
  end

  @spec add_rules(RuleGroup.t(), [Rule.t()]) :: RuleGroup.t()
  def add_rules(rule_group, rules) do
    # NOTE - we add each rule one at a time so we can confirm that it is a Rule.t
    {_rules, rule_group} = Enum.map_reduce(rules, rule_group, fn(rule, acc) -> {rule, add_rule(acc, rule)} end)
    rule_group
  end

  def get_sorted_rules(rule_group) do
    rule_group.rules |> Enum.sort(&(Map.get(&1, :priority) <= Map.get(&2, :priority)))
  end

end
