alias Hermetic.{YouTrack}

defmodule Hermetic.Slash.Cmd do
  @moduledoc ~S"""
  Handle `/yt-cmd issue-id command`.
  """

  import Hermetic.Slash
  import Plug.Conn

  use Plug.ErrorHandler

  def init([]), do: []

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, 200, "Wrong syntax, use: issue-id command")
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
