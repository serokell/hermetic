defmodule Hermetic.MixProject do
  use Mix.Project

  def project do
    [
      app: :hermetic,
      version: "0.1.0",
      deps: [{:slack, "~> 0.14.0"}]
    ]
  end

  def application do
    [
      env: [
        slack_token: "",
	yt_prefix: "https://issues.serokell.io/",
        yt_token: "",
      ],
      mod: {Hermetic, []}
    ]
  end
end
