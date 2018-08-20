defmodule Hermetic do
  @moduledoc """
    Slack bot that links to YouTrack issues.
  """

  use Application

  def start(_, _) do
    children = [
      {Plug.Adapters.Cowboy2, plug: Hermetic.Router, scheme: :http, options: [port: 8080]},
      Hermetic.Cache.child_spec(
        %{function: &Hermetic.YouTrack.project_ids/0},
        name: Hermetic.YouTrack.ProjectIDs
      )
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
