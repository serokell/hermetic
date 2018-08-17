alias Hermetic.YouTrack.ProjectIdCache

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
    headers = [{"authorization", "bearer " <> token()}, {"accept", "application/json"}]
    HTTPoison.get!(base_url() <> endpoint, headers).body |> Poison.decode!()
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

  def cached_project_ids do
    ProjectIdCache.get()
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
