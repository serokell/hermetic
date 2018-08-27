alias Hermetic.{YouTrack, Attachment, Slack}

defmodule Hermetic.Slash do
  @moduledoc """
  Handles Slack slash commands
  """

  import Plug.Conn

  use Plug.ErrorHandler

  def init([]), do: []

  @doc """
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

  @doc """
  Split off the first word based on whitespace.
  Returns a tuple of the first word and the remainder.
  """
  @spec split_word(String.t()) :: [String.t()]
  def split_word(string) do
    string
    |> String.trim_leading()
    |> String.split(~r/\s+|$/, parts: 2)
  end

  @doc ~S"""
  Split off the first escaped tag (channel) or user or unescaped tag.

  ## Examples

      iex> split_tag("<@U1234|john> remainder")
      {:user, "U1234", "remainder"}

      iex> split_tag("<#C1234|channel> remainder")
      {:tag, "channel", "remainder"}

      iex> split_tag("#tag remainder")
      {:tag, "tag", "remainder"}

      iex> split_tag("nothing")
      {:none, "", "nothing"}
  """
  @spec split_tag(String.t()) :: {:none | :user | :tag, String.t(), String.t()}
  def split_tag(string) do
    re = ~r/^\s*(?:(?:\<\@([^\|]+)\|[^\>]+\>)|(?:\<\#[^\|]+\|([^\>]+)\>)|(?:\#(\S+)))\s*(.*)$/
    string = String.trim(string)
    case Regex.run(re, string) do
      [_, user, "", "", remainder] ->
        {:user, user, remainder}
      [_, "", tag, "", remainder] ->
        {:tag, tag, remainder}
      [_, "", "", tag, remainder] ->
        {:tag, tag, remainder}
      nil ->
        {:none, "", string}
    end
  end

  @doc """
  Split off #tags and @assignees and return a tuple with them and the
  remainder.
  """
  @spec split_tags(String.t(), [String.t()], [String.t()]) :: {[String.t()], [String.t()], String.t()}
  def split_tags(string, assignees \\ [], tags \\ []) do
    {type, head, tail} = split_tag(string)
    case type do
      :user ->
        split_tags(tail, assignees ++ [head], tags)
      :tag ->
        split_tags(tail, assignees, tags ++ [head])
      :none ->
        {assignees, tags, String.trim(string)}
    end
  end

  @doc """
  Translate a Slack user id to a YouTrack login name.
  """
  @spec translate_user(String.t()) :: String.t()
  def translate_user(slack_user) do
    YouTrack.emails_to_logins()[Slack.user_email(slack_user)]
  end

  @doc """
  Translate any Slack users mentioned to YouTrack logins.
  """
  @spec translate_users(String.t()) :: String.t()
  def translate_users(command) do
    Regex.replace(~r/\<\@([^\|]+)\|[^\>]+\>/, command,
      fn _, slack_id -> translate_user(slack_id) end)
  end

  def call(conn, []) do
    case conn.body_params["command"] do
      "/yt-add" -> yt_add(conn)
      "/yt-cmd" -> yt_cmd(conn)
    end
  end

  @doc """
  Build a command to tag an issue.
  """
  @spec tag_command(String.t()) :: String.t()
  def tag_command(tag) do
    "tag " <> String.replace(tag, "_", " ")
  end

  @doc """
  Build a command to add assignees to an issue.
  """
  @spec assignee_command(String.t()) :: String.t()
  def assignee_command(assignee) do
    "add " <> translate_user(assignee)
  end

  @doc """
  Handle `/yt-add projectid [@assignee] [#tag] Title text`.
  """
  @spec yt_add(Plug.Conn.t()) :: Plug.Conn.t()
  def yt_add(conn) do
    [project, rest] = split_word(conn.body_params["text"])
    {assignees, tags, title} = split_tags(rest)
    issue = YouTrack.create_issue(project, title, "")
    # TODO: Work out policy for tag creation and visibility
    assignees = Enum.map(assignees, &assignee_command/1)
    tags = Enum.map(tags, &tag_command/1)
    YouTrack.execute_command(issue, Enum.join(assignees ++ tags, " "))
    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(200, Jason.encode!(%{
      "response_type": "in_channel",
      "attachments": [Attachment.new(issue)],
    }))
  end

  @doc """
  Handle `/yt-cmd issue-id command`.
  """
  @spec yt_cmd(Plug.Conn.t()) :: Plug.Conn.t()
  def yt_cmd(conn) do
    [issue, command] = split_word(conn.body_params["text"])
    command = translate_users(command)
    result = YouTrack.execute_command(issue, command).body
    result = case result do
      "" -> "Done: #{issue} #{command}"
      x -> String.replace(x, ~r/\<[^\>]*\>/, "") # Strip XML tags
    end
    send_resp(conn, 200, result)
  end
end
