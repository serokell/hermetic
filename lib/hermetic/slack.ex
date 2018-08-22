defmodule Hermetic.Slack do
  @moduledoc """
    Slack API client.
  """

  import ConfigMacro

  @doc """
    Slack API token.
    
    Get one at: <https://api.slack.com/apps?new_app_token=1>
  """
  @spec token() :: String.t()
  config :hermetic, [:token]

  # Slack API base URL.
  @base_url "https://slack.com/api"

  def request(endpoint, payload) do
    HTTPoison.post!(@base_url <> endpoint, Jason.encode!(payload), [
      {"authorization", "Bearer " <> token()},
      {"content-type", "application/json"}
    ])
  end

  @spec get_email(String.t()) :: String.t()
  def get_email(userid) do
    resp = HTTPoison.get!(@base_url <> "/users.profile.get?" <> URI.encode_query([
      token: token(),
      user: userid,
    ]), [])
    Jason.decode!(resp.body)["profile"]["email"]
  end

  @doc """
    Send given payload to chat.postMessage Slack API endpoint.

    See: <https://api.slack.com/methods/chat.postMessage>
  """
  def send_message(payload) do
    request("/chat.postMessage", payload)
  end
end
