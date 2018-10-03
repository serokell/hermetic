defmodule Hermetic do
  @moduledoc ~S"""
  Slack bot that links to YouTrack issues.
  """

  import ConfigMacro
  config :hermetic, [:cowboy_options]

  use Application

  def start(_, _) do
    children = [
      {Plug.Adapters.Cowboy2, plug: Hermetic.Router, scheme: :http, options: cowboy_options()},
      Hermetic.YouTrack.ProjectID,
      Hermetic.YouTrack.EmailsToLogins
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
