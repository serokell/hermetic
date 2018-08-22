alias Hermetic.{YouTrack, Attachment}

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

  @doc """
    Split off #tags and @assignees and return a tuple with them and the
    remainder.
  """
  @spec split_tags(String.t(), [String.t()], [String.t()]) :: {[String.t()], [String.t()], String.t()}
  def split_tags(string, assignees \\ [], tags \\ []) do
    [head, tail] = split_word(string)
    case String.at(string, 0) do
      "@" ->
        split_tags(tail, assignees ++ [head], tags)
      "#" ->
        split_tags(tail, assignees, tags ++ [head])
      _ ->
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
