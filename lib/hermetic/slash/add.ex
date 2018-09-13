alias Hermetic.{YouTrack, Attachment}

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
  Parse the /yt-add command.
  """
  @spec parse_yt_add(String.t()) :: {String.t(), [String.t()], [String.t()], String.t()}
  def parse_yt_add(command) do
    command = OptionParser.split(command)
    [project | command] = command
    command = Enum.map(command, &tokenize/1)
    %{:tag => tags, :user => assignees, :text => words} =
      Map.merge(%{:tag => [], :user => [], :text => []},
        Enum.group_by(command, fn {key, _} -> key end, fn {_, value} -> value end))
    assignees = Enum.map(assignees, &translate_user_id/1)
    {project, tags, assignees, Enum.join(words, " ")}
  end

  def call(conn, []) do
    {project, tags, assignees, title} = parse_yt_add(conn.body_params["text"])
    sender = translate_user_id(conn.body_params["user_id"])
    issue = YouTrack.create_issue(project, title, "")
    # TODO: Work out policy for tag creation and visibility
    assignees = Enum.map(assignees, fn assignee -> "for " <> assignee end)
    tags = Enum.map(tags, fn tag -> "tag " <> tag end)
    command = Enum.join(assignees ++ tags, " ")
    error = YouTrack.execute_command(issue, command, sender).body
    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(200, Jason.encode!(%{
      text: strip_xml_tags(error),
      response_type: "in_channel",
      attachments: [Attachment.new(issue)],
    }))
  end
end
