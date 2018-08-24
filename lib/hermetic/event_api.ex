alias Hermetic.{Attachment, Slack, YouTrack}

defmodule Hermetic.EventAPI do
  @moduledoc """
  Slack Event API handler.
  """

  import Plug.Conn

  def init([]), do: []

  @doc """
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

  @doc """
  Turn enumerable into a regular expression group.

  ```
  "(a|b|c)" = enum_to_regex_group(["a", "b", "c"])
  ```
  """
  @spec enum_to_regex_group(list(String.t())) :: String.t()
  def enum_to_regex_group(list) do
    "(" <> Enum.join(list, "|") <> ")"
  end

  @doc """
  Extract YouTrack issue IDs for all known projects from arbitrary text.
  """
  @spec extract_issue_ids(String.t()) :: MapSet.t(String.t())
  def extract_issue_ids(text) do
    project_ids = YouTrack.cached_project_ids() |> enum_to_regex_group()

    ~r/#{project_ids}-[1-9][0-9]{0,3}/
    |> Regex.scan(text, capture: :first)
    |> Enum.map(&List.first/1)
    |> MapSet.new()
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

          unless Enum.empty?(attachments), do: provide_metadata(event, attachments)
        end

        send_resp(conn, 200, "")

      "url_verification" ->
        send_resp(conn, 200, payload["challenge"])
    end
  end
end
