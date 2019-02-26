# RulesEngine

A port of the EasyRules (rules engine) to Elixir
http://www.easyrules.org/

Please read the EasyRules link for a quick intro to the concepts and workflows.

- Implements default rules engine
- Implements inference rules engine (rules continue to fire while any of the conditions are true)
- Implements all rules engine parameters
- Implements all rule groups (UnitRuleGroup, ActivationRuleGroup, ConditionalRuleGroup)
- **DOES NOT** implement rules listener or rules engine listener

## Authors/Contributors

Bob Sollish - Author/maintainer

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rules_engine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rules_engine, "~> 0.1.0"}
  ]
end
```

## Fizz-Buzz Example

(Look at test/rules_engine_test.exs for more examples)

```elixir
defmodule FizzBuzzWithRulesEngine do
  def main() do
    # RulesEngineParameters
    params = RulesEngineParameters.create(%{skip_on_first_applied_rule: true})

    # --------------------------------------------
    # define our individual rules
    fizz_rule = %Rule{
      name: "FizzRule",
      priority: 1,
      condition: fn(facts) -> rem(facts.number, 5) == 0 end,
      actions: [IO.puts("fizz")]}

    buzz_rule = %Rule{
      name: "BuzzRule",
      priority: 2,
      condition: fn(facts) -> rem(facts.number, 7) == 0 end,
      actions: [IO.puts("buzz")]}

    fizz_buzz_rule = RuleGroup.create(%{
      name: "FizzBuzzRule",
      type: :unit_rule_group,
      rules: [fizz_rule, buzz_rule],
      priority: 0})

    non_fizz_buzz_rule = %Rule{
      name: "NonFizzBuzzRule",
      priority: 3,
      condition: fn(facts) -> rem(facts.number, 5) != 0 || rem(facts.number, 7) != 0 end,
      actions: [fn(facts) -> IO.puts(Kernel.inspect(facts.number)) end]}
    # --------------------------------------------

    # create set of rules
    rules = Rule.add_rules([fizz_rule, buzz_rule, fizz_buzz_rule, non_fizz_buzz_rule])

    # run our rules engine 100 times - with values (number facts) from 1 to 100 (inclusive)
    for n <- 1..100 do
      facts = %{number: n}
      RulesEngine.fire(params, rules, facts)
      IO.puts("")
    end
  end
end
```

Running FizzBuzzWithRulesEngine.main() will output:
```text
1
2
3
4
fizz
6
buzz
8
9
fizz
11
12
13
buzz
fizz
16
17
18
19
fizz
buzz
22
23
24
fizz
26
27
buzz
29
fizz
31
32
33
34
fizzbuzz
36
37
38
39
fizz
41
buzz
43
44
fizz
46
47
48
buzz
fizz
51
52
53
54
fizz
buzz
57
58
59
fizz
61
62
buzz
64
fizz
66
67
68
69
fizzbuzz
71
72
73
74
fizz
76
buzz
78
79
fizz
81
82
83
buzz
fizz
86
87
88
89
fizz
buzz
92
93
94
fizz
96
97
buzz
99
fizz
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/rules_engine](https://hexdocs.pm/rules_engine).
