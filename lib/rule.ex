defmodule Rule do

  defstruct name: "",
            description: "",
            priority: 0,
            condition: nil,
            actions: []

  @type t :: %Rule{
          name: String.t(),
          description: String.t(),
          priority: non_neg_integer(),
          condition: function(),
          actions: [function()]
        }

  def add_rule(rule, rules_map \\ %{}) do
    Map.put(rules_map, String.to_atom(rule.name), rule)
  end

  def add_rules(rules_list) do
    Enum.reduce(rules_list, %{}, fn(rule, rules) -> add_rule(rule, rules) end)
  end
end
