defmodule Hermetic.Router do
  import ConfigMacro

  @doc """
    Valid Slack API application signing secrets.
  """
  @spec slack_secrets :: Cobwebhook.secrets()
  config :hermetic, [:slack_secrets]

  use Plug.Router

  plug(Cobwebhook.Slack, &__MODULE__.slack_secrets/0)

  plug(:match)
  plug(:dispatch)

  forward("/", to: Hermetic.EventAPI)
end
