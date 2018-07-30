alias Hermetic.OAuth

defmodule Hermetic.YouTrack do
  import ConfigMacro
  config :hermetic, [:base_url, :token]

  def request(path) do
    headers = [OAuth.bearer(token()), {"accept", "application/json"}]
    HTTPoison.get!(base_url() <> path, headers).body |> Poison.decode!()
  end

  def avatar_url(username) do
    base_url() <> request("/api/admin/users/#{username}?fields=avatarUrl")["avatarUrl"]
  end

  def logo_url do
    base_url() <> "/static/apple-touch-icon-180x180.png"
  end

  def project_ids do
    for %{"shortName" => id} <- request("/rest/project/all"), do: id
  end

  def issue_data(issue_id) do
    if fields = Map.get(request("/rest/issue/#{issue_id}"), "field") do
      for field = %{"name" => name} <- fields, into: %{}, do: {name, field}
    end
  end
end
