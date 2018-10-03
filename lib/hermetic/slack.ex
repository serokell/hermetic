defmodule Hermetic.Slack do
  @moduledoc ~S"""
  Slack API client.
  """

  use HTTPoison.Base

  import ConfigMacro

  @doc ~S"""
  Slack API token.

  Get one at: <https://api.slack.com/apps?new_app_token=1>
  """
  @spec token() :: String.t()
  config :hermetic, [:token]

  # Slack API base URL.
  @base_url "https://slack.com/api"

  def process_url(url) do
    @base_url <> url
  end

  def process_request_headers(headers) do
    headers ++
      [
        {"Authorization", "Bearer " <> token()},
        # API doesn't work without Content-Type
        {"Content-Type", "application/json"}
      ]
  end

  def process_request_body(""), do: ""
  def process_request_body(body), do: Jason.encode!(body)

  def process_response_body(""), do: ""
  def process_response_body(body), do: Jason.decode!(body)

  @doc ~S"""
  Get the profile for a user id.
  """
  @spec user_profile(String.t()) :: map()
  def user_profile(user_id) do
    get!("/users.profile.get", [],
      params: [
        user: user_id
      ]
    ).body["profile"]
  end

  @doc ~S"""
  Return a permalink to the most recent message in a slack channel.
  """
  @spec channel_context(String.t()) :: String.t()
  def channel_context(channel) do
    %{"ok" => true, "messages" => [%{"ts" => timestamp}]} =
      get!("/conversations.history", [],
        params: [
          channel: channel,
          limit: 1
        ]
      ).body

    %{"ok" => true, "permalink" => permalink} =
      get!("/chat.getPermalink", [],
        params: [
          channel: channel,
          message_ts: timestamp
        ]
      ).body

    permalink
  end

  @doc ~S"""
  Send given payload to chat.postMessage Slack API endpoint.

  See: <https://api.slack.com/methods/chat.postMessage>
  """
  def send_message(payload) do
    post!("/chat.postMessage", payload)
  end
end
