defmodule RulesEngineParameters do
  @moduledoc """
  For reference from https://github.com/j-easy/easy-rules/wiki/defining-rules-engine
  Parameter	                    Type	   Required	 Default
  rulePriorityThreshold	        int	     no	       MaxInt
  skipOnFirstAppliedRule	      boolean	 no	       false
  skipOnFirstFailedRule	        boolean	 no	       false
  skipOnFirstNonTriggeredRule	  boolean	 no	       false

  The skipOnFirstAppliedRule parameter tells the engine to skip next rules when a rule is applied.
  The skipOnFirstFailedRule parameter tells the engine to skip next rules when a rule fails.
  The skipOnFirstNonTriggeredRule parameter tells the engine to skip next rules when a rule is not triggered.
  The rulePriorityThreshold parameter tells the engine to skip next rules if priority exceeds the defined threshold.
  """

  defstruct rule_priority_threshold: 1_000_000_000,
            skip_on_first_applied_rule: false,
            skip_on_first_failed_rule: false,
            skip_on_first_non_triggered_rule: false

  @type t :: %RulesEngineParameters{
          rule_priority_threshold: non_neg_integer(),
          skip_on_first_applied_rule: boolean(),
          skip_on_first_failed_rule: boolean(),
          skip_on_first_non_triggered_rule: boolean()
        }

  alias __MODULE__

  def default_rules_engine_parameters() do
    %RulesEngineParameters{}
  end

  def create(params) when is_map(params) do
    Map.merge(%RulesEngineParameters{}, params)
  end

end
