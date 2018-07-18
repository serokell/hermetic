defmodule YT do
  def request(url) do
    token = Application.get_env(:hermetic, :yt_token)
    headers = ["Authorization": "Bearer #{token}", "Accept": "Application/json"]
    {:ok, response} = HTTPoison.get(prefix() <> url, headers)
    response.body |> Poison.decode!
  end
  def short_projects do
    for %{"shortName" => n} <- request("rest/project/all"), do: n
  end
  def issue(issue) do
    result = request("rest/issue/#{issue}")
    if Map.has_key? result, "value" do
      result["value"]
    else
      for (field = %{"name" => name}) <- result["field"], into: %{}, do:
                  {String.to_atom(name),
                   (for {propname, content} <- field, into: %{}, do: {String.to_atom(propname), content})}
    end
  end
  def avatar(username) do
    prefix() <> request("api/admin/users/#{username}?fields=avatarUrl")["avatarUrl"]
  end
  def prefix do
    Application.get_env(:hermetic, :yt_prefix)
  end
  def logo do
    prefix() <> "/static/apple-touch-icon-180x180.png"
  end
end
defmodule YTCache do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> [] end)
  end
  def get_projs(bucket) do
    Agent.get(bucket, fn n -> n end)
  end
  def update_projs(bucket) do
    projects = YT.short_projects
    Agent.update(bucket, fn _ -> projects end)
  end

end
