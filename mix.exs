defmodule Hermetic.MixProject do
  use Mix.Project

  def project do
    [
      app: :hermetic,
      deps: [
        {:config_macro, "~> 0.1.0"},
        {:slack, "~> 0.14.0"}
      ],
      version: "0.1.0"
    ]
  end

  def application do
    [mod: {Hermetic, []}]
  end
end
