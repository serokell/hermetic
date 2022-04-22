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
      {"Authorization", "Bearer " <> token()},
      {"Accept", "application/json"}
    ]

    HTTPoison.request!(method, base_url() <> endpoint, "", headers, params: params)
  end

  def post(endpoint, fields, body) do
    resp = HTTPoison.post!(base_url() <> "/api/" <> endpoint, Jason.encode!(Map.new(body)),
      [{"Authorization", "Bearer " <> token()},
       {"Content-Type", "application/json"}
      ],
      params: [fields: Enum.join(fields)]
    )
    Jason.decode!(resp.body)
  end

  @doc ~S"""
  Create a new issue and return the issue id.
  """
  @spec create_issue(String.t(), String.t(), String.t()) :: String.t()
  def create_issue(project, summary, description) do
    projectId = cached_project_ids()[String.upcase(project)]
    post("issues", ["idReadable"], 
      project: %{id: projectId},
      summary: summary,
      description: description
    )["idReadable"]
  end

  @doc ~S"""
  Execute YouTrack command on an issue.
  """
  @spec execute_command(String.t(), String.t(), String.t()) :: HTTPoison.Response.t()
  def execute_command(issue, command, sender) do
    post("commands", ["entityID"],
      query: command,
      runAs: sender,
      issues: [%{idReadable: issue}])
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
    @spec refresh :: %{String.t() => String.t()}
    def refresh do
      projects = Jason.decode!(YouTrack.request(:get, "/api/admin/projects", fields: "shortName,id").body)
      for %{"shortName" => shortName, "id" => id} <- projects, into: %{}, do: {shortName, id}
    end
  end

  @spec cached_project_ids :: %{String.t() =>String.t()}
  def cached_project_ids do
    ProjectID.retrieve(ProjectID)
  end

  defmodule EmailsToLogins do
    use LambdaCache, name: __MODULE__

    @max_int32 0x7FFF_FFFF

    @spec refresh :: %{String.t() => String.t()}
    def refresh do
      for %{"login" => login, "profile" => %{"email" => %{"email" => email}}} <-
        (YouTrack.request(:get,
          "/hub/api/rest/users", "$top": @max_int32, fields: "login,profile/email/email"
        ).body |> Jason.decode!())["users"],
          into: %{},
          do: {email, login}
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
    data = Jason.decode!(request(:get, "/api/issues/#{issue_id}", fields: Enum.join([
              "summary", "description", "idReadable", "reporter(login,avatarUrl,fullName)",
              "created",
              "customFields(name,value(name,login,fullName,color(background)))"
            ], ",")).body)

    if fields = Map.get(data, "customFields") do
      for field = %{"name" => name} <- fields, into: data, do: {name, field}
    end
  end
end
