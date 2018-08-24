alias Hermetic.YouTrack

defmodule Hermetic.Attachment do
  @doc """
  Format URL and text to form a Slack link.

  See: <https://api.slack.com/docs/message-formatting#linking_to_urls>
  """
  @spec slack_link(String.t(), String.t()) :: String.t()
  def slack_link(url, text) do
    "<#{url}|#{text}>"
  end

  @doc """
  Create a Slack attachment that would describe a YouTrack issue given its issue data.

  See: <https://api.slack.com/docs/message-attachments>
  """
  def new(issue_id) do
    if issue_data = YouTrack.issue_data(issue_id), do: render(issue_id, issue_data)
  end

  def render(issue_id, issue_data) do
    %{
      author_icon: YouTrack.avatar_url(issue_data["reporterName"]["value"]),
      author_link: YouTrack.base_url() <> "/users/" <> issue_data["reporterName"]["value"],
      author_name: issue_data["reporterFullName"]["value"],
      color: issue_data["State"]["color"]["bg"],
      fields: [
        %{title: "State", value: List.first(issue_data["State"]["value"]), short: true},
        if Map.has_key?(issue_data, "Assignees") do
          assignees =
            for %{"fullName" => full_name, "value" => username} <-
                  issue_data["Assignees"]["value"],
                do: slack_link(YouTrack.base_url() <> "/users/#{username}", full_name)

          %{title: "Assignees", value: Enum.join(assignees, ","), short: true}
        end
      ],
      footer: "YouTrack",
      footer_icon: YouTrack.logo_url(),
      text:
        if Map.has_key?(issue_data, "description") do
          issue_data["description"]["value"]
        end,
      title: "[#{issue_id}] #{issue_data["summary"]["value"]}",
      title_link: YouTrack.base_url() <> "/issue/" <> issue_id,
      ts: String.to_integer(issue_data["created"]["value"]) / 1000
    }
  end
end
