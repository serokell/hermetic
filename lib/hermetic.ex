defmodule Hermetic do
  @moduledoc """
    Slack bot that links to YouTrack issues.
  """

  use Application

  def start(_, _) do
    children = [Hermetic.SlackBot, Hermetic.YouTrack.ProjectIdCache]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
