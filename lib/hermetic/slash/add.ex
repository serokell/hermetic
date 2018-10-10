alias Hermetic.{Slack, YouTrack, Attachment}

defmodule Hermetic.Slash.Add do
  @moduledoc ~S"""
  Handle `/yt-add projectid [@assignee] [#tag] Title text`.
  """

  import Hermetic.Slash
  import Plug.Conn

  use Plug.ErrorHandler

  def init([]), do: []

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, 200, "Wrong syntax, use: projectid [@assignee] [#tag] Title text")
  end

  @doc ~S"""
  Parse one token.
  """
  @spec tokenize(String.t()) :: {:text | :user | :tag, String.t()}
  def tokenize("<@" <> id_name) do
    [id, _] = String.split(id_name, "|")
    {:user, id}
  end

  def tokenize("<#" <> id_name) do
    [_, name] = String.split(id_name, "|")
    {:tag, String.trim_trailing(name, ">")}
  end

  def tokenize("#" <> tag), do: {:tag, tag}
  def tokenize(text), do: {:text, text}

  @doc ~S"""
  Translate a part of the title to YouTrack terms
  """
  @spec translate_title({:text | :user | :tag, String.t()}) :: String.t()
  def translate_title({:tag, tag}), do: "##{tag}"
  def translate_title({:text, text}), do: text

  def translate_title({:user, slack_id}) do
    Slack.user_profile(slack_id)["real_name"]
  end

  @doc ~S"""
  Parse the /yt-add command.
  """
  @spec parse_yt_add(String.t()) :: {String.t(), [String.t()], [String.t()], String.t()}
  def parse_yt_add(command) do
    [project | command] = split(command)

    {command, title} =
      command
      |> Enum.map(&tokenize/1)
      |> Enum.split_while(fn {key, _} -> key != :text end)

    %{:tag => tags, :user => assignees} =
      Map.merge(
        %{:tag => [], :user => []},
        Enum.group_by(command, fn {key, _} -> key end, fn {_, value} -> value end)
      )

    assignees = Enum.map(assignees, &translate_user_id/1)

    title =
      title
      |> Enum.map(&translate_title/1)
      |> Enum.join(" ")

    {project, tags, assignees, title}
  end

  def call(conn, []) do
    {project, tags, assignees, title} = parse_yt_add(conn.body_params["text"])
    sender = translate_user_id(conn.body_params["user_id"])
    context = Slack.channel_context(conn.body_params["channel_id"])
    issue = YouTrack.create_issue(project, title, context)

    assignees = Enum.map(assignees, fn assignee -> "for " <> assignee end)
    tags = Enum.map(tags, fn tag -> "tag " <> tag end)
    command = Enum.join(assignees ++ tags, " ")
    error = YouTrack.execute_command(issue, command, sender).body

    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(
      200,
      Jason.encode!(%{
        text: strip_xml_tags(error),
        response_type: "in_channel",
        attachments: [Attachment.new(issue)]
      })
    )
  end
end
