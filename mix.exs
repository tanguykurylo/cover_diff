defmodule CoverDiff.MixProject do
  use Mix.Project

  def project do
    [
      app: :cover_diff,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "CoverDiff",
      source_url: "https://https://github.com/tanguykurylo/cover_diff",
      docs: [
        main: "CoverDiff",
        extras: ["README.md"]
      ],
      description: "Generate coverage reports for the code in a git diff",
      package: [
        licenses: ["MIT"],
        links: %{
          "Github Repository" => "https://https://github.com/tanguykurylo/cover_diff"
        }
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :tools, :eex]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
