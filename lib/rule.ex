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

end
