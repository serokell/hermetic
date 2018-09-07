defmodule Hermetic do
  @moduledoc ~S"""
  Slack bot that links to YouTrack issues.
  """

  use Application

  def start(_, _) do
    children = [
      {Plug.Adapters.Cowboy2, plug: Hermetic.Router, scheme: :http, options: [port: 8080]},
      Hermetic.YouTrack.ProjectID,
      Hermetic.YouTrack.EmailsToLogins,
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
