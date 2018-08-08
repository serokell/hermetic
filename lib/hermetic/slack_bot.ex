alias Hermetic.{OAuth, YouTrack}

defmodule Hermetic.SlackBot do
  @moduledoc """
    Slack RTM bot with a simplistic API client and processing logic.
  """

  import ConfigMacro
  config :hermetic, [:token]

  use Slack

  def child_spec(_) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}}
  end

  def start_link do
    Slack.Bot.start_link(__MODULE__, [], token(), %{name: __MODULE__})
  end

  @doc """
    Send given payload to chat.postMessage Slack API endpoint.

    See: <https://api.slack.com/methods/chat.postMessage>
  """
  def send_message(payload) do
    url = "https://slack.com/api/chat.postMessage"
    headers = [OAuth.bearer(token()), {"content-type", "application/json"}]
    HTTPoison.post!(url, Poison.encode!(payload), headers)
  end

  @doc """
    Respond with attachments to the given incoming Slack RTM message.

    Will mirror message's channel and thread.
  """
  def respond(message, attachments) do
    send_message(%{
      attachments: attachments,
      channel: message.channel,
      thread_ts: Map.get(message, :thread_ts)
    })
  end

  @doc """
    Turn enumerable into a regular expression group.

    ```
    "(a|b|c)" = enum_to_regex_group(["a", "b", "c"])
    ```
  """
  @spec enum_to_regex_group(list(String.t())) :: String.t()
  def enum_to_regex_group(list) do
    "(" <> Enum.join(list, "|") <> ")"
  end

  @doc """
    Match arbitrary text to extract YouTrack IDs of all currently known projects.
  """
  @spec issue_ids(String.t()) :: MapSet.t(String.t())
  def issue_ids(text) do
    project_ids = enum_to_regex_group(YouTrack.ProjectIdCache.get())

    ~r/#{project_ids}-[1-9][0-9]{0,3}/
    |> Regex.scan(text, capture: :first)
    |> Enum.map(&List.first/1)
    |> MapSet.new()
  end

  # Ignore other Slack bots:
  def handle_event(%{bot_id: _}, _, state), do: {:ok, state}

  def handle_event(message = %{type: "message", text: text}, _, state) do
    unless Enum.empty?(issue_ids = issue_ids(text)) do
      respond(message, Enum.map(issue_ids, &issue_attachment/1))
    end

    {:ok, state}
  end

  def handle_event(_, _, state), do: {:ok, state}

  @doc """
    Format URL and text to form a Slack link.

    See: <https://api.slack.com/docs/message-formatting#linking_to_urls>
  """
  def slack_link(url, text) do
    "<#{url}|#{text}>"
  end

  @doc """
    Create a Slack attachment that would describe a YouTrack issue given its ID.

    See: <https://api.slack.com/docs/message-attachments>
  """
  def issue_attachment(issue_id) do
    if data = YouTrack.issue_data(issue_id) do
      %{
        author_icon: YouTrack.avatar_url(data["reporterName"]["value"]),
        author_link: YouTrack.base_url() <> "/users/" <> data["reporterName"]["value"],
        author_name: data["reporterFullName"]["value"],
        color: data["State"]["color"]["bg"],
        fields: [
          %{title: "State", value: List.first(data["State"]["value"]), short: true},
          if Map.has_key?(data, "Assignees") do
            assignees =
              for %{"fullName" => full_name, "value" => username} <- data["Assignees"]["value"],
                  do: slack_link(YouTrack.base_url() <> "/users/#{username}", full_name)

            %{title: "Assignees", value: Enum.join(assignees, ","), short: true}
          end
        ],
        footer: "YouTrack",
        footer_icon: YouTrack.logo_url(),
        text:
          if Map.has_key?(data, "description") do
            data["description"]["value"]
          end,
        title: "[#{issue_id}] #{data["summary"]["value"]}",
        title_link: YouTrack.base_url() <> "/issue/" <> issue_id,
        ts: String.to_integer(data["created"]["value"]) / 1000
      }
    end
  end
end
