defmodule YT do
  def request(url) do
    token = Application.get_env(:sb2, :yt_token)
    headers = ["Authorization": "Bearer #{token}", "Accept": "Application/json"]
    {:ok, response} = HTTPoison.get("https://issues.serokell.io/" <> url, headers)
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
      Map.new result["field"], fn (thing = %{"name" => nm}) -> {(String.to_atom nm), (Map.new thing, fn {a,b} -> {(String.to_atom a), b} end)} end
    end
  end
  def avatar(username) do
    "https://issues.serokell.io#{request("api/admin/users/#{username}?fields=avatarUrl")["avatarUrl"]}"
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
