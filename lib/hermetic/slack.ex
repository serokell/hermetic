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
    headers ++ [
      {"Authorization", "Bearer " <> token()},
    ]
  end

  def process_request_body(""), do: ""
  def process_request_body(body), do: Jason.encode!(body)

  def process_response_body(""), do: ""
  def process_response_body(body), do: Jason.decode!(body)

  @doc ~S"""
  Get the email address for a user id.
  """
  @spec user_email(String.t()) :: String.t()
  def user_email(user_id) do
    get!("/users.profile.get", [], params: [
      user: user_id,
    ]).body["profile"]["email"]
  end

  @doc ~S"""
  Send given payload to chat.postMessage Slack API endpoint.

  See: <https://api.slack.com/methods/chat.postMessage>
  """
  def send_message(payload) do
    post!("/chat.postMessage", payload)
  end
end
