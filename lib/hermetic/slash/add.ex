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
  Split a string into whitespace delimited or quoted parts

      iex> split("Foo foon't \"bar bazn't\"")
      ["Foo", "foon't", "bar bazn't"]
  """
  @spec split(String.t()) :: [String.t()]
  def split(string) do
    do_split(String.trim_leading(string, " "), "", [], false)
  end

  # Any character after a backslash is taken literally
  @spec do_split(String.t(), String.t(), [String.t()], bool) :: [String.t()]
  defp do_split(<<?\\, c, rest::binary>>, buf, acc, quoting),
    do: do_split(rest, <<buf::binary, c>>, acc, quoting)

  # Toggle quoting on double quote
  defp do_split(<<?", rest::binary>>, buf, acc, quoting),
    do: do_split(rest, buf, acc, !quoting)

  # Start a new segment after an unquoted space
  defp do_split(<<?\s, rest::binary>>, buf, acc, false),
    do: do_split(String.trim_leading(rest, " "), "", [buf | acc], false)

  # Any other character is simply copied
  defp do_split(<<c, rest::binary>>, buf, acc, quoting),
    do: do_split(rest, <<buf::binary, c>>, acc, quoting)

  # Finish string or raise if unclosed
  defp do_split(<<>>, "", acc, false), do: Enum.reverse(acc)
  defp do_split(<<>>, buf, acc, false), do: Enum.reverse([buf | acc])
  defp do_split(<<>>, _, _, _), do: raise "quoted string not closed"

  @doc ~S"""
  Parse the /yt-add command.
  """
  @spec parse_yt_add(String.t()) :: {String.t(), [String.t()], [String.t()], String.t()}
  def parse_yt_add(command) do
    command = split(command)
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
