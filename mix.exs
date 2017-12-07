defmodule Adyen.Mixfile do
  use Mix.Project

  def project do
    [
      app: :adyen,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      test_coverage: [
        tool: ExCoveralls
      ],
      preferred_cli_env: [
        coveralls: :test
      ],
      dialyzer: [
        ignore_warnings: "dialyzer.ignore-warnings",
        flags: [
          :unmatched_returns,
          :error_handling,
          :race_conditions,
        ],
        paths: ["_build/dev/lib/adyen/ebin"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Adyen.Supervisor, []}
    ]
  end

  defp deps do
    [
      {:cortex, ">= 0.0.0", only: [:dev, :test]},
      {:maxwell, ">= 0.0.0"},
      {:exvcr, ">= 0.0.0", only: [:dev, :test]},
      {:ecto, ">= 0.0.0"},
      {:exiban, ">= 0.0.0"},
      {:timex, ">= 0.0.0"},
      {:poison, ">= 0.0.0"},
      {:hackney, ">= 0.0.0"},
      {:excoveralls, ">= 0.0.0", only: [:test]},
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false},
      {:credo, ">= 0.0.0", only: [:test, :dev]},
    ]
  end
end
