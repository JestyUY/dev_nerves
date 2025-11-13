defmodule DevNerves.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/jestyUY/dev_nerves"

  def project do
    [
      app: :dev_nerves,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Package info for publishing to Hex
      description: "Mix task to create Nerves projects with dev container setup for Windows users",
      package: package(),

      # Docs
      name: "DevNerves",
      source_url: @source_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :eex],
      mod: {DevNerves.Application, []}
    ]
  end

  defp deps do
    [
      # For nice CLI interactions (multi-select, etc.)
      {:owl, "~> 0.11"},

      # For documentation
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["jestyUY"],
      links: %{
        "GitHub" => @source_url
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
