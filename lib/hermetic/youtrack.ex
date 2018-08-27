alias Hermetic.{Cache, YouTrack}

defmodule Hermetic.YouTrack do
  @moduledoc """
  YouTrack API client.
  """

  import ConfigMacro
  config :hermetic, [:base_url, :token]

  @doc """
  Send HTTP GET request to provided YouTrack endpoint.
  """
  def request(method, endpoint, params \\ []) do
    headers = [
      {"authorization", "Bearer " <> token()},
      {"accept", "application/json"}
    ]

    HTTPoison.request!(method, base_url() <> endpoint, "", headers, [params: params])
  end

  @doc """
  Create a new issue and return the issue id
  """
  @spec create_issue(String.t(), String.t(), String.t()) :: String.t()
  def create_issue(project, summary, description) do
    resp = request(:put, "/rest/issue", [
      project: String.upcase(project),
      summary: summary,
      description: description,
    ])
    headers = Map.new(resp.headers)
    headers["Location"] |> String.split("/") |> List.last
  end

  @doc """
  Execute YouTrack command on an issue
  """
  @spec execute_command(String.t(), String.t()) :: HTTPoison.Response.t()
  def execute_command(issue, command) do
    request(:post, "/rest/issue/#{issue}/execute", [command: command])
  end

  @doc """
  Return URL to YouTrack avatar for the given username.
  """
  def avatar_url(username) do
    resp = request(:get, "/api/admin/users/#{username}", [fields: "avatarUrl"])
    base_url() <> Jason.decode!(resp.body)["avatarUrl"]
  end

  @doc """
  Return URL to YouTrack logo.
  """
  def logo_url do
    base_url() <> "/static/apple-touch-icon-180x180.png"
  end

  @doc """
  Fetch list of all available YouTrack project IDs.
  """
  @spec project_ids :: list(String.t())
  def project_ids do
    json = Jason.decode!(request(:get, "/rest/project/all").body)
    for %{"shortName" => id} <- json, do: id
  end

  @spec cached_project_ids :: list(String.t())
  def cached_project_ids do
    Cache.get(YouTrack.ProjectIDs)
  end

  @spec emails_to_logins :: %{String.t() => String.t()}
  def emails_to_logins do
    for %{"login" => login, "profile" => %{"email" => %{"email" => email}}} <-
      Jason.decode!(request(:get, "/hub/rest/users?" <> URI.encode_query([
        "$top": 0x7fffffff,
        fields: "login,profile/email/email",
      ])).body)["users"], into: %{}, do: {email, login}
  end

  @spec cached_emails_to_logins :: %{String.t() => String.t()}
  def cached_emails_to_logins do
    Cache.get(YouTrack.EmailsToLogins)
  end

  @doc """
  Fetch YouTrack data for an issue, given its ID.
  """
  def issue_data(issue_id) do
    json = Jason.decode!(request(:get, "/rest/issue/#{issue_id}").body)
    if fields = Map.get(json, "field") do
      for field = %{"name" => name} <- fields, into: %{}, do: {name, field}
    end
  end
end
