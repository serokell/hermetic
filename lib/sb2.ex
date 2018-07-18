defmodule Sb2 do
  use Mix.Config
  @moduledoc """
  Documentation for Sb2.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Sb2.hello
      :world

  """
  def hello do
    :world
  end
  def start do
    slack_token = Application.get_env(:slack, :api_token)
    {:ok, ytcache} = YTCache.start_link []
    YTCache.update_projs(ytcache)
    {:ok, rtm} = Slack.Bot.start_link(SlackRtm, [ytcache], slack_token)
  end
end
defmodule SlackRtm do
  use Slack

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    IO.puts (inspect state)
    {:ok, state}
  end

  # ignore bot messages
  def handle_event(%{subtype: "bot_message"}, _, state), do: {:ok, state}
  def handle_event(message = %{type: "message", text: text}, slack, [ytcache]) do
    IO.puts (inspect message)
    yt_projs = YTCache.get_projs(ytcache)
    regex = "(?:^|[^/])\\b((#{Enum.join yt_projs, "|"})-([1-9][0-9]{0,3}))\\b"
    matches = Regex.scan(Regex.compile!(regex), text)
    if length(matches) > 0 do
      issues = for [_, issue | _] <- matches do
        ytinfo = YT.issue(issue)
        %{
          "title": "[#{issue}] #{ytinfo.summary.value}",
          "text": if Map.has_key? ytinfo, "description" do ytinfo.description.value end,
          "title_link": "https://issues.serokell.io/issue/#{issue}",
          "author_icon": YT.avatar(ytinfo.reporterName.value),
          "color": ytinfo."State".color["bg"],
          "footer": "Youtrack",
          "footer_icon": "https://issues.serokell.io/static/apple-touch-icon-180x180.png",
          "author_name": ytinfo.reporterFullName.value,
          "author_link": "https://issues.serokell.io/users/#{ytinfo.reporterName.value}",
          "ts": (String.to_integer ytinfo.created.value) / 1000,
          "fields": [%{"title": "State", "value": Enum.at(ytinfo."State".value, 0), "short": true}]
        }
      end
      Slack.Web.Chat.post_message(message.channel, "", %{attachments: issues |> Poison.encode!})
    end
    {:ok, [ytcache]}
  end
  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    # send pid, {:message, "hello", #operations}
    IO.puts "Sending your message, captain!"

    send_message(text, channel, slack)

    {:ok, state}
  end
  def handle_info(_, _, state), do: {:ok, state}
end
