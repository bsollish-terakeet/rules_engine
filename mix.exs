defmodule RulesEngine.MixProject do
  use Mix.Project

  def project() do
    [
      app: :rules_engine,
      version: "0.1.0",
      elixir: "~> 1.6",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/bsollish-terakeet/rules_engine"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application() do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps() do
    [
      {:ex_doc, "~> 0.14", only: :dev}
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
