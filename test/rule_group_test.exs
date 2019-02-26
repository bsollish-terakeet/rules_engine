defmodule RuleGroupTest do
  use ExUnit.Case

  alias RulesEngine.Rule
  alias RulesEngine.RuleGroup, as: RG
  alias RulesEngine.RulesEngineTest, as: RET

  @moduletag :rules_engine

  setup_all do
    rule1 = %Rule{
      name: "rule one",
      description: "I am the description for rule one",
      priority: 1,
      condition: &RET.greater_than_zero_rule/1,
      actions: [&RET.greater_than_zero_action/1, &RET.greater_than_zero_action2/1, &RET.greater_than_zero_action3/1]}

    rule2 = %Rule{
      name: "rule two",
      description: "I am the description for rule two",
      priority: 5,
      condition: &RET.greater_than_ten_rule/1,
      actions: [&RET.greater_than_ten_action/1, &RET.greater_than_ten_action2/1]}

    %{rule1: rule1, rule2: rule2}
  end

  setup do
    %{}
  end

  describe "rule group" do
    test "create rule groups and add rules", %{rule1: rule1, rule2: rule2} do

      rule_group1 = RG.create(:unit_rule_group)

      assert rule_group1.type == :unit_rule_group

      catch_error(RG.create(:bad_rule_group))

      rule_group2 = RG.create(:activation_rule_group, [rule1, rule2])

      assert rule_group2.type == :activation_rule_group
      assert rule_group2.rules == [rule1, rule2]

      rule_group3 = RG.create(%{type: :conditional_rule_group})

      assert rule_group3.type == :conditional_rule_group

      rule_group4 = RG.create(%{type: :conditional_rule_group, rules: [rule1, rule2]})

      assert rule_group4.type == :conditional_rule_group
      assert rule_group4.rules == [rule1, rule2]

      catch_error(RG.create(%{type: :unit_rule_group, rules: [:not_a_rule, rule2]}))

      catch_error(RG.add_rule(rule_group1, :not_a_rule))

      rule_group1 = RG.add_rule(rule_group1, rule1)
      rule_group1 = RG.add_rule(rule_group1, rule2)

      assert rule_group1.rules == [rule1, rule2]

      catch_error(RG.add_rules(rule_group3, [:not_a_rule, rule2]))

      rule_group3 = RG.add_rules(rule_group3, [rule1, rule2])

      assert rule_group3.rules == [rule1, rule2]
    end
  end

end
