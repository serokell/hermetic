alias Hermetic.{Attachment, YouTrack}

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
    Regex.replace(~r/\<\@([^\|]+)\|[^\>]+\>/, command, fn _, slack_id ->
      translate_user_id(slack_id)
    end)
  end

  @doc ~S"""
  Respond to a command using its response_url.
  """
  def respond([issue, command], params) do
    sender = translate_user_id(params["user_id"])
    command = translate_any_users(command)
    result = YouTrack.execute_command(issue, command, sender).body

    response =
      case result do
        "" ->
          %{
            text: "Done: #{issue} #{command}",
            response_type: "in_channel",
            attachments: [Attachment.new(issue)]
          }

        error ->
          %{
            text: Jason.decode!(error)["value"]
          }
      end

    HTTPoison.post!(params["response_url"], Jason.encode!(response))
  end

  def call(conn, []) do
    parsed = String.split(conn.body_params["text"], ~r/\s+/, parts: 2)
    Task.start(fn -> respond(parsed, conn.body_params) end)
    send_resp(conn, 200, "")
  end
end
