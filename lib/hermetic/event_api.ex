alias Hermetic.{Attachment, Slack, YouTrack}

defmodule Hermetic.EventAPI do
  @moduledoc ~S"""
  Slack Event API handler.
  """

  import ConfigMacro

  @doc ~S"""
  Maximum number of attachments per message.
  """
  @spec max_attachments() :: pos_integer()
  config :hermetic, max_attachments: 3

  import Plug.Conn

  def init([]), do: []

  @doc ~S"""
  Respond with attachments to the given incoming Slack message, mirroring its channel and thread.
  """
  def provide_metadata(event, attachments) do
    %{
      attachments: attachments,
      channel: event["channel"],
      thread_ts: Map.get(event, "thread_ts")
    }
    |> Slack.send_message()
  end

  @doc ~S"""
  Turn enumerable into a regular expression group.

      iex> enum_to_regex_group(["a", "b", "c"])
      "(a|b|c)"
  """
  @spec enum_to_regex_group(list(String.t())) :: String.t()
  def enum_to_regex_group(list) do
    "(" <> Enum.join(list, "|") <> ")"
  end

  @doc ~S"""
  Extract YouTrack issue IDs for all known projects from arbitrary text.
  """
  @spec extract_issue_ids(String.t()) :: [String.t()]
  def extract_issue_ids(text) do
    project_ids = YouTrack.cached_project_ids() |> Map.keys() |> enum_to_regex_group()

    ~r/#{project_ids}-[1-9][0-9]{0,3}/
    |> Regex.scan(text, capture: :first)
    |> Enum.map(&List.first/1)
    |> Enum.uniq()
  end

  def this_or_nothing?(map, key, value) do
    Map.get(map, key, value) == value
  end

  def call(conn, []) do
    payload = conn.body_params

    case payload["type"] do
      "event_callback" ->
        event = payload["event"]

        if event["type"] == "message" && this_or_nothing?(event, "subtype", "message_replied") do
          attachments =
            extract_issue_ids(event["text"])
            |> Enum.map(&Attachment.new/1)
            |> Enum.reject(&is_nil/1)
            |> Enum.take(max_attachments())

          unless Enum.empty?(attachments) do
            Task.start(fn -> provide_metadata(event, attachments) end)
          end
        end

        send_resp(conn, 200, "")

      "url_verification" ->
        send_resp(conn, 200, payload["challenge"])
    end
  end
end
