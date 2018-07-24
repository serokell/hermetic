defmodule Hermetic do
  use Application

  def start(_type, _args) do
    Hermetic.Supervisor.start_link(name: Hermetic.Supervisor)
  end
end

defmodule Hermetic.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {YTCache, name: YTCache},
      %{
        id: Slack.Bot,
        start: {Slack.Bot, :start_link, [SlackRtm, [], Application.get_env(:hermetic, :slack_token)]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
