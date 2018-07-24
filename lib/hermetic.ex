defmodule Hermetic do
  use Application

  def slack_token do
    Application.get_env(:hermetic, :slack_token)
  end

  def start(_, _) do
    children = [
      {YTCache, name: YTCache},
      %{
        id: Slack.Bot,
        start: {Slack.Bot, :start_link, [SlackRtm, [], slack_token()]}
      }
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
