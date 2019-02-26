defmodule RulesEngineTest do
  use ExUnit.Case
  use Agent

  alias Rule
  alias RulesEngine, as: RE
  alias InferenceRulesEngine, as: IRE
  alias RulesEngineParameters, as: REP
  alias RuleGroup, as: RG

  @moduletag :rules_engine

  @text_files_folder "/text_files"

  @simple_multi_rule_check_filepath __DIR__ <> @text_files_folder <> "/simple_multi_rule_output_check.txt"
  @reduced_priority_multi_rule_check_filepath __DIR__ <> @text_files_folder <> "/reduced_priority_multi_rule_output_check.txt"
  @fizz_buzz_check_filepath __DIR__ <> @text_files_folder <> "/fizz_buzz_output_check.txt"

  setup_all do
    rule1 = %Rule{
      name: "rule one",
      description: "I am the description for rule one",
      priority: 1,
      condition: &greater_than_zero_rule/1,
      actions: [&greater_than_zero_action/1, &greater_than_zero_action2/1, &greater_than_zero_action3/1]}

    rule2 = %Rule{
      name: "rule two",
      description: "I am the description for rule two",
      priority: 5,
      condition: &greater_than_ten_rule/1,
      actions: [&greater_than_ten_action/1, &greater_than_ten_action2/1]}

    rule3 = %Rule{
      name: "rule three",
      description: "I am the description for rule three",
      priority: 3,
      condition: &greater_than_five_rule/1,
      actions: [&greater_than_five_action/1]}

    params1 = REP.default_rules_engine_parameters()
    params2 = REP.create(%{rule_priority_threshold: 4})

    %{rule1: rule1, rule2: rule2, rule3: rule3, params1: params1, params2: params2}
  end

  setup do
    %{}
  end

  describe "rules engine" do
    test "hello world", %{} do

      rule1 = %Rule{name: "rule one",
                    description: "I am the description for rule one",
                    priority: 1,
                    condition: fn(_x) -> true end,
                    actions: [fn(_x) -> throw("Hello World") end]}

      rules = %{}
      rules = Map.put(rules, String.to_atom(rule1.name), rule1)

      facts = %{}

      assert catch_throw(RE.fire(REP.default_rules_engine_parameters(), rules, facts)) == "Hello World"
    end

    @tag :RWS1
    test "simple multi rule", %{rule1: rule1, rule2: rule2, rule3: rule3, params1: params} do
      rules = add_rule(rule1)
      rules = add_rule(rule2, rules)
      rules = add_rule(rule3, rules)

      rules2 = add_rules([rule1, rule2, rule3])

      # confirm both methods yield the same result
      assert rules == rules2

      Agent.start_link(fn -> "" end, name: __MODULE__)

      facts = %{number: 7}
      RE.fire(params, rules, facts)

      facts = %{number: 12}
      RE.fire(params, rules, facts)

      {:ok, check} = File.read(@simple_multi_rule_check_filepath)
      assert Agent.get(__MODULE__, & &1) == check

      Agent.stop(__MODULE__)
    end

    test "simple multi rule - with reduced priority threshold", %{rule1: rule1, rule2: rule2, rule3: rule3, params2: params} do
      rules = add_rules([rule1, rule2, rule3])

      Agent.start_link(fn -> "" end, name: __MODULE__)

      for n <- [-2, 2, 7, 12] do
        RE.fire(params, rules, %{number: n})
      end

      {:ok, check} = File.read(@reduced_priority_multi_rule_check_filepath)
      assert Agent.get(__MODULE__, & &1) == check

      Agent.stop(__MODULE__)
    end

    test "skip_on_first_failed_rule", %{} do
      list = [&succeeds/0, &succeeds/0, &fails/0, &succeeds/0]

      result = Enum.reduce_while(list, true, fn(rule, _acc) ->
        case rule.() do
          :ok -> {:cont, true}
          {:error, _} -> {:halt, false}
        end
      end)

      assert result == false

      list = [&succeeds/0, &succeeds/0, &succeeds/0]

      result = Enum.reduce_while(list, true, fn(rule, _acc) ->
        case rule.() do
          :ok -> {:cont, true}
          {:error, _} -> {:halt, false}
        end
      end)

      assert result == true
    end
  end

  describe "FizzBuzz example" do
    test "fizz buzz 1 to 100", %{} do
      params = REP.create(%{skip_on_first_applied_rule: true})

      Agent.start_link(fn -> "" end, name: __MODULE__)

      fizz_rule = %Rule{
        name: "FizzRule",
        priority: 1,
        condition: fn(facts) -> rem(facts.number, 5) == 0 end,
        actions: [update_agent_func("fizz")]}

      buzz_rule = %Rule{
        name: "BuzzRule",
        priority: 2,
        condition: fn(facts) -> rem(facts.number, 7) == 0 end,
        actions: [update_agent_func("buzz")]}

      fizz_buzz_rule = RG.create(%{
        name: "FizzBuzzRule",
        type: :unit_rule_group,
        rules: [fizz_rule, buzz_rule],
        priority: 0})

      non_fizz_buzz_rule = %Rule{
        name: "NonFizzBuzzRule",
        priority: 3,
        condition: fn(facts) -> rem(facts.number, 5) != 0 || rem(facts.number, 7) != 0 end,
        actions: [fn(facts) -> Agent.update(__MODULE__, &(&1 <> Kernel.inspect(facts.number))) end]}

      rules = add_rules([fizz_rule, buzz_rule, fizz_buzz_rule, non_fizz_buzz_rule])

      for n <- 1..100 do
        RE.fire(params, rules, %{number: n})
        write_to_agent("\n")
      end

      {:ok, check} = File.read(@fizz_buzz_check_filepath)

      assert Agent.get(__MODULE__, & &1) == check

      Agent.stop(__MODULE__)
    end
  end

  describe "InferenceRulesEngine" do
    test "HVAC/thermostat example", %{params1: params} do
      # create ets table for HVAC
      hvac_table = :ets.new(:hvac_table, [])

      rules = add_rules([
        %Rule{name: "StartCoolingRule", priority: 2, condition: &start_cooling_rule/1, actions: [&start_cooling_action/1]},
        %Rule{name: "StopCoolingRule",  priority: 0, condition: &stop_cooling_rule/1,  actions: [&stop_cooling_action/1] },
        %Rule{name: "StartHeatingRule", priority: 2, condition: &start_heating_rule/1, actions: [&start_heating_action/1]},
        %Rule{name: "StopHeatingRule",  priority: 0, condition: &stop_heating_rule/1,  actions: [&stop_heating_action/1] },
        %Rule{name: "DecreaseTempRule", priority: 1, condition: &decrease_temp_rule/1, actions: [&decrease_temp_action/1]},
        %Rule{name: "IncreaseTempRule", priority: 1, condition: &increase_temp_rule/1, actions: [&increase_temp_action/1]}])

      # facts holds hvac ets table
      facts = %{table: hvac_table}

      # set initial HVAC state
      set_hvac(hvac_table, :off, 65, 70, 2)

      hvac = get_hvac(hvac_table)

      assert hvac == %{system: :off, temperature: 65, thermostat: 70, plus_minus: 2}

      IRE.fire(params, rules, facts)

      assert get_hvac(hvac_table, :system) == :off
      assert get_hvac(hvac_table, :temperature) == 71

      IO.puts("")

      # set initial HVAC state
      set_hvac(hvac_table, :off, 78, 70, 2)

      IRE.fire(params, rules, facts)

      assert get_hvac(hvac_table, :system) == :off
      assert get_hvac(hvac_table, :temperature) == 69

      # delete ets table for HVAC
      :ets.delete(hvac_table)
    end
  end

  # ========================================

  defp update_agent_func(content), do: fn(_facts) -> write_to_agent(content) end

  defp write_to_agent(content), do: Agent.update(__MODULE__, &(&1 <> content))

  defp start_cooling_rule(facts) do
    get_hvac(facts.table, :system) == :off &&
    get_hvac(facts.table, :temperature) > get_hvac(facts.table, :thermostat) + get_hvac(facts.table, :plus_minus)
  end

  defp start_cooling_action(facts), do: set_hvac(facts.table, :system, :cooling)

  defp stop_cooling_rule(facts) do
    get_hvac(facts.table, :system) == :cooling &&
    get_hvac(facts.table, :temperature) < get_hvac(facts.table, :thermostat)
  end

  defp stop_cooling_action(facts), do: set_hvac(facts.table, :system, :off)

  defp start_heating_rule(facts) do
    get_hvac(facts.table, :system) == :off &&
    get_hvac(facts.table, :temperature) < get_hvac(facts.table, :thermostat) - get_hvac(facts.table, :plus_minus)
  end

  defp start_heating_action(facts), do: set_hvac(facts.table, :system, :heating)

  defp stop_heating_rule(facts) do
    get_hvac(facts.table, :system) == :heating &&
    get_hvac(facts.table, :temperature) > get_hvac(facts.table, :thermostat)
  end

  defp stop_heating_action(facts), do: set_hvac(facts.table, :system, :off)

  defp decrease_temp_rule(facts), do: get_hvac(facts.table, :system) == :cooling

  defp decrease_temp_action(facts), do: set_hvac(facts.table, :temperature, get_hvac(facts.table, :temperature) - 1)

  defp increase_temp_rule(facts), do: get_hvac(facts.table, :system) == :heating

  defp increase_temp_action(facts), do: set_hvac(facts.table, :temperature, get_hvac(facts.table, :temperature) + 1)

  defp set_hvac(table, state, temp, thermostat, plus_minus) do
    :ets.insert(table, [{:system, state}, {:temperature, temp}, {:thermostat, thermostat}, {:plus_minus, plus_minus}])
  end

  defp set_hvac(table, param, value) do

    IO.puts("set_hvac: #{inspect(param)} -> #{inspect(value)}")

    :ets.insert(table, [{param, value}])
  end

  defp get_hvac(table) do
    %{system:       get_hvac(table, :system     ),
      temperature:  get_hvac(table, :temperature),
      thermostat:   get_hvac(table, :thermostat ),
      plus_minus:   get_hvac(table, :plus_minus )}
  end

  defp get_hvac(table, param) do
    [{_, value}] = :ets.lookup(table, param)
    value
  end

  def greater_than_zero_rule(facts) do
    write_to_agent("Greater_than_zero_rule (#{inspect(Map.get(facts, :number))})\n")

    if Map.get(facts, :number) > 0 do
      true
    else
      false
    end
  end

  def greater_than_five_rule(facts) do
    write_to_agent("Greater_than_five_rule (#{inspect(Map.get(facts, :number))})\n")

    if Map.get(facts, :number) > 5 do
      true
    else
      false
    end
  end

  def greater_than_ten_rule(facts) do
    write_to_agent("Greater_than_ten_rule (#{inspect(Map.get(facts, :number))})\n")

    if Map.get(facts, :number) > 10 do
      true
    else
      false
    end
  end

  def greater_than_zero_action(_facts),  do: write_to_agent("___Greater than zero (1)\n")
  def greater_than_zero_action2(_facts), do: write_to_agent("___Greater than zero (2)\n")
  def greater_than_zero_action3(_facts), do: write_to_agent("___Greater than zero (3)\n")

  def greater_than_five_action(_facts),  do: write_to_agent("___Greater than five\n")

  def greater_than_ten_action(_facts),   do: write_to_agent("___Greater than ten (1)\n")
  def greater_than_ten_action2(_facts),  do: write_to_agent("___Greater than ten (2)\n")

  def succeeds(), do: :ok

  def fails(), do: {:error, "reason"}

  def add_rule(rule, rules_map \\ %{}) do
    Map.put(rules_map, String.to_atom(rule.name), rule)
  end

  def add_rules(rules_list) do
    Enum.reduce(rules_list, %{}, fn(rule, rules) -> add_rule(rule, rules) end)
  end

end
