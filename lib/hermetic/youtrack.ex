alias Hermetic.YouTrack

defmodule Hermetic.YouTrack do
  @moduledoc ~S"""
  YouTrack API client.
  """

  import ConfigMacro
  config :hermetic, [:base_url, :token]

  @doc ~S"""
  Send HTTP GET request to provided YouTrack endpoint.
  """
  def request(method, endpoint, params \\ []) do
    headers = [
      {"authorization", "Bearer " <> token()},
      {"accept", "application/json"}
    ]

    HTTPoison.request!(method, base_url() <> endpoint, "", headers, [params: params])
  end

  @doc ~S"""
  Create a new issue and return the issue id.
  """
  @spec create_issue(String.t(), String.t(), String.t()) :: String.t()
  def create_issue(project, summary, description) do
    resp = request(:put, "/rest/issue", [
      project: String.upcase(project),
      summary: summary,
      description: description,
    ])
    Path.basename(Map.new(resp.headers)["Location"])
  end

  @doc ~S"""
  Execute YouTrack command on an issue.
  """
  @spec execute_command(String.t(), String.t(), String.t()) :: HTTPoison.Response.t()
  def execute_command(issue, command, sender) do
    request(:post, "/rest/issue/#{issue}/execute", [
      command: command,
      runAs: sender,
    ])
  end

  @doc ~S"""
  Return URL to YouTrack avatar for the given username.
  """
  def avatar_url(username) do
    resp = request(:get, "/api/admin/users/#{username}", [fields: "avatarUrl"])
    base_url() <> Jason.decode!(resp.body)["avatarUrl"]
  end

  @doc ~S"""
  Return URL to YouTrack logo.
  """
  def logo_url do
    base_url() <> "/static/apple-touch-icon-180x180.png"
  end

  defmodule ProjectID do
    use LambdaCache, name: __MODULE__

    @doc ~S"""
    Fetch list of all available YouTrack project IDs.
    """
    @spec refresh :: list(String.t())
    def refresh do
      projects = Jason.decode!(YouTrack.request(:get, "/rest/project/all").body)
      for %{"shortName" => id} <- projects, do: id
    end
  end

  @spec cached_project_ids :: list(String.t())
  def cached_project_ids do
    ProjectID.retrieve(ProjectID)
  end

  defmodule EmailsToLogins do
    use LambdaCache, name: __MODULE__

    @max_int32 0x7fff_ffff

    @spec refresh :: %{String.t() => String.t()}
    def refresh do
      for %{"login" => login, "profile" => %{"email" => %{"email" => email}}} <-
        Jason.decode!(YouTrack.request(:get, "/hub/rest/users?" <> URI.encode_query([
          "$top": @max_int32,
          fields: "login,profile/email/email",
        ])).body)["users"], into: %{}, do: {email, login}
    end
  end

  @spec cached_emails_to_logins :: %{String.t() => String.t()}
  def cached_emails_to_logins do
    EmailsToLogins.retrieve(EmailsToLogins)
  end

  @doc ~S"""
  Fetch YouTrack data for an issue, given its ID.
  """
  def issue_data(issue_id) do
    data = Jason.decode!(request(:get, "/rest/issue/#{issue_id}").body)
    if fields = Map.get(data, "field") do
      for field = %{"name" => name} <- fields, into: %{}, do: {name, field}
    end
  end
end
