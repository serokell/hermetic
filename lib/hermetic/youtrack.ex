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
  def request(endpoint) do
    headers = [
      {"authorization", "Bearer " <> token()},
      {"accept", "application/json"}
    ]

    HTTPoison.get!(base_url() <> endpoint, headers).body |> Jason.decode!()
  end

  @doc """
    Send HTTP PUT request to provided YouTrack endpoint.
  """
  def put!(endpoint) do
    headers = [
      {"authorization", "Bearer " <> token()},
    ]

    HTTPoison.put!(base_url() <> endpoint, "", headers)
  end

  @doc """
    Send HTTP POST request to provided YouTrack endpoint.
  """
  def post!(endpoint, body) do
    headers = [
      {"authorization", "Bearer " <> token()},
    ]

    HTTPoison.post!(base_url() <> endpoint, body, headers)
  end

  def create_issue(project, summary, description) do
    resp = put!("/rest/issue?" <> URI.encode_query([
      project: String.upcase("bot"),
      summary: summary,
      description: description,
    ]))
    headers = Map.new(resp.headers)
    headers["Location"] |> String.split("/") |> List.last
  end

  def execute_command(issue, command) do
    resp = post!("/rest/issue/#{issue}/execute", URI.encode_query([
      command: command,
      comment: "[debug] Command sent: " <> command,
    ]))
  end

  def add_tags(issue, tags) do
    command = tags
              |> Enum.map(fn x -> "tag " <> String.trim(x, "#") end)
              |> Enum.join(" ")
    execute_command(issue, command)
  end

  def add_assignees(issue, assignees) do
    command = assignees
              |> Enum.map(fn x -> "add " <> String.trim(x, "@") end)
              |> Enum.join(" ")
    execute_command(issue, command)
  end

  @doc """
    Return URL to YouTrack avatar for the given username.
  """
  def avatar_url(username) do
    base_url() <> request("/api/admin/users/#{username}?fields=avatarUrl")["avatarUrl"]
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
    for %{"shortName" => id} <- request("/rest/project/all"), do: id
  end

  @spec project_ids :: list(String.t())
  def cached_project_ids do
    Cache.get(YouTrack.ProjectIDs)
  end

  @doc """
    Fetch YouTrack data for an issue, given its ID.
  """
  def issue_data(issue_id) do
    if fields = Map.get(request("/rest/issue/#{issue_id}"), "field") do
      for field = %{"name" => name} <- fields, into: %{}, do: {name, field}
    end
  end
end
