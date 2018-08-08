defmodule Hermetic.MixProject do
  use Mix.Project

  def project do
    [
      app: :hermetic,
      deps: [
        {:config_macro, "~> 0.1.0"},
        {:dialyxir, "~> 0.5", only: :dev, runtime: false},
        {:ex_doc, "~> 0.18.0", only: :dev, runtime: false},
        {:slack, "~> 0.14.0"}
      ],
      version: "0.1.0"
    ]
  end

  def application do
    [mod: {Hermetic, []}]
  end
end
