defmodule Questie.MixProject do
  use Mix.Project

  def project do
    [
      app: :questie,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Rut "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.8", only: :test},
      {:finch, "~> 0.6", only: :test},
      {:jason, "~> 1.2", only: :test, runtime: false}
    ]
  end
end
