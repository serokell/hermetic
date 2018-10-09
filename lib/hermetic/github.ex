defmodule Hermetic.Github do
  @moduledoc ~S"""
  Github API client.
  """

  use HTTPoison.Base

  import ConfigMacro

  @doc ~S"""
  Github API token.

  Necessary scopes: `repo_deployment`
  """
  @spec token() :: String.t()
  config :hermetic, [:token]

  def process_url(url) do
    "https://api.github.com" <> url
  end

  def process_request_headers(headers) do
    headers ++ [{"Authorization", "token " <> token()}]
  end

  def process_request_body(""), do: ""
  def process_request_body(body), do: Jason.encode!(body)

  def process_response_body(""), do: ""
  def process_response_body(body), do: Jason.decode!(body)

  @doc ~S"""
  Create a GitHub deployment.
  """
  @spec deploy(String.t(), String.t(), String.t(), String.t()) :: %HTTPoison.Response{
          status_code: integer()
        }
  def deploy(owner, repo, ref, env) do
    post!("/repos/#{owner}/#{repo}/deployments", %{ref: ref, environment: env})
  end
end
