alias Hermetic.{YouTrack, Attachment, Slack}

defmodule Hermetic.Slash do
  @moduledoc ~S"""
  Handles Slack slash commands
  """

  import Plug.Conn

  use Plug.ErrorHandler

  def init([]), do: []

  @doc ~S"""
  Return usage string given a /command.
  """
  @spec usage :: %{String.t() => String.t()}
  def usage do
    %{
      "/yt-add" => "projectid [@assignee] [#tag] Title text",
      "/yt-cmd" => "issue-id command",
    }
  end

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, 200, "Wrong syntax. Usage: "
    <> usage()[conn.body_params["command"]])
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
  Translate a Slack user id to a YouTrack login name.
  """
  @spec translate_user_id(String.t()) :: String.t()
  def translate_user_id(slack_id) do
    YouTrack.emails_to_logins()[Slack.user_email(slack_id)]
  end

  @doc ~S"""
  Translate any Slack users mentioned to YouTrack logins.
  """
  @spec translate_any_users(String.t()) :: String.t()
  def translate_any_users(command) do
    Regex.replace(~r/\<\@([^\|]+)\|[^\>]+\>/, command,
      fn _, slack_id -> translate_user_id(slack_id) end)
  end

  def call(conn, []) do
    case conn.body_params["command"] do
      "/yt-add" -> yt_add(conn)
      "/yt-cmd" -> yt_cmd(conn)
    end
  end

  @doc ~S"""
  Parse the /yt-add command.
  """
  @spec parse_yt_add(String.t()) :: {String.t(), [String.t()], [String.t()], String.t()}
  def parse_yt_add(command) do
    command = OptionParser.split(command)
    [project | command] = command
    command = Enum.map(command, &tokenize/1)
    %{:tag => tags, :user => assignees, :text => words} =
      Enum.group_by(command, fn {key, _} -> key end, fn {_, value} -> value end)
    assignees = Enum.map(assignees, &translate_user_id/1)
    {project, tags, assignees, Enum.join(words, " ")}
  end

  @doc ~S"""
  Strip all xml tags from a string.
  """
  @spec strip_xml_tags(String.t()) :: String.t()
  def strip_xml_tags(xml) do
    String.replace(xml, ~r/\<[^\>]*\>/, "")
  end

  @doc ~S"""
  Handle `/yt-add projectid [@assignee] [#tag] Title text`.
  """
  @spec yt_add(Plug.Conn.t()) :: Plug.Conn.t()
  def yt_add(conn) do
    {project, tags, assignees, title} = parse_yt_add(conn.body_params["text"])
    issue = YouTrack.create_issue(project, title, "")
    # TODO: Work out policy for tag creation and visibility
    assignees = Enum.map(assignees, fn assignee -> "add " <> assignee end)
    tags = Enum.map(tags, fn tag -> "tag " <> tag end)
    error = YouTrack.execute_command(issue, Enum.join(assignees ++ tags, " ")).body
    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(200, Jason.encode!(%{
      "text": strip_xml_tags(error),
      "response_type": "in_channel",
      "attachments": [Attachment.new(issue)],
    }))
  end

  @doc ~S"""
  Handle `/yt-cmd issue-id command`.
  """
  @spec yt_cmd(Plug.Conn.t()) :: Plug.Conn.t()
  def yt_cmd(conn) do
    [issue, command] = String.split(conn.body_params["text"], ~r/\s+/, parts: 2)
    command = translate_any_users(command)
    result = YouTrack.execute_command(issue, command).body
    result = case result do
      "" -> "Done: #{issue} #{command}"
      error -> strip_xml_tags(error)
    end
    send_resp(conn, 200, result)
  end
end
