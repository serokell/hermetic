alias Hermetic.{YouTrack, Attachment, Slack}

defmodule Hermetic.Slash do
  @moduledoc """
    Handles Slack slash commands
  """

  import Plug.Conn

  use Plug.ErrorHandler

  def init([]), do: []

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, 200, "Usage: projectid [@assignee] [#tag] Title text")
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
      {:none, nil, "nothing"}
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
        {assignees, tags, string}
    end
  end

  def call(conn, []) do
    [project, rest] = split_word(conn.body_params["text"])
    {assignees, tags, title} = split_tags(rest)
    issue = YouTrack.create_issue(project, title, "")
    # TODO: Translate assignees from slack to youtrack names
    # TODO: Work out policy for tag creation and visibility
    YouTrack.add_tags(issue, tags)
    YouTrack.add_assignees(issue, assignees)
    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(200, Jason.encode!(%{
      "response_type": "in_channel",
      "attachments": [Attachment.new(issue)],
    }))
  end
end
