defmodule Hermetic.MixProject do
  use Mix.Project

  def project do
    [
      app: :hermetic,
      deps: [
        {:lambda_cache, github: "serokell/lambda_cache"},
        {:config_macro, "~> 0.1.0"},
        {:cobwebhook, "~> 0.4.0"},
        {:cowboy, "~> 2.4.0"},
        {:dialyxir, "~> 0.5", only: :dev, runtime: false},
        {:ex_doc, "~> 0.18.0", only: :dev, runtime: false},
        {:httpoison, "~> 1.2.0"},
        {:jason, "~> 1.1"},
        {:plug, "~> 1.6.1"}
      ],
      version: "0.1.0"
    ]
  end

  def application do
    [mod: {Hermetic, []}]
  end
end
