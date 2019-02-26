defmodule RulesEngine.MixProject do
  use Mix.Project

  def project() do
    [
      app: :rules_engine,
      version: "0.1.1",
      elixir: "~> 1.6",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "RulesEngine",
      source_url: "https://github.com/bsollish-terakeet/rules_engine",
      homepage_url: "https://github.com/bsollish-terakeet/rules_engine",
      docs: [
        main: "RulesEngine", # The main page in the docs
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application() do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps() do
    [
      {:ex_doc, "~>0.18.0", only: :dev}
    ]
  end

  defp description() do
    "A port of the EasyRules (rules engine) to Elixir."
  end

  def package do
    [
      contributors: ["Bob Sollish"],
      maintainers: ["Bob Sollish"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/bsollish-terakeet/rules_engine"}
    ]
  end
end
