alias Hermetic.YouTrack

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

  def split_word(string) do
    String.split(string, ~r/\s+|$/, parts: 2)
  end

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
    # TODO: Update issue with assignees and tags
    send_resp(conn, 200, "#{inspect issue} created.")
  end
end
