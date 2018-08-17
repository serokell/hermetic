defmodule Hermetic.Pipeline do
  import ConfigMacro
  config :hermetic, [:secrets]

  use Plug.Builder

  plug(Cobwebhook.Slack, &__MODULE__.secrets/0)
  plug(Hermetic.Webhook)
end
