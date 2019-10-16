defmodule MoveMavenArtifacts.MixProject do
  use Mix.Project

  def project do
    [
      app: :move_maven_artifacts,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.5"},
      {:floki, "~> 0.23.0"}
    ]
  end
end
