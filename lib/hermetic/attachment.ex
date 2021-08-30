alias Hermetic.YouTrack

defmodule Hermetic.Attachment do
  @moduledoc ~S"""
  Create a Slack attachment that would describe a YouTrack issue given its issue data.
  """

  import ConfigMacro

  @doc ~S"""
  Maximum size of attachment description.
  """
  @spec max_text_size() :: pos_integer()
  config :hermetic, max_text_size: 280

  @doc ~S"""
  Format URL and text to form a Slack link.

  See: <https://api.slack.com/docs/message-formatting#linking_to_urls>
  """
  @spec slack_link(String.t(), String.t()) :: String.t()
  def slack_link(url, text) do
    "<#{url}|#{text}>"
  end

  @doc ~S"""
  Create a Slack attachment that would describe a YouTrack issue given its issue data.

  See: <https://api.slack.com/docs/message-attachments>
  """
  def new(issue_id) do
    if issue_data = YouTrack.issue_data(issue_id), do: render(issue_data)
  end

  @doc ~S"""
  Cut off long strings to a limited number of characters and an ellipsis.
  """
  @spec cutoff(String.t(), pos_integer()) :: String.t()
  def cutoff(text, amount) do
    if String.length(text) > amount do
      String.slice(text, 0, amount - 3) <> "..."
    else
      text
    end
  end

  @doc ~S"""
  Build the Slack attachment map from the YouTrack issue data map
  """
  @spec render(map()) :: map()
  def render(issue_data) do
    %{
      author_icon: YouTrack.base_url() <> issue_data["reporter"]["avatarUrl"],
      author_link: YouTrack.base_url() <> "/users/" <> issue_data["reporter"]["login"],
      author_name: issue_data["reporter"]["fullName"],
      color: issue_data["State"]["value"]["color"]["background"],
      fields: [
        if Map.has_key?(issue_data, "State") do
          %{title: "State", value: issue_data["State"]["value"]["name"], short: true}
        end,
        if Map.has_key?(issue_data, "Assignees") or Map.has_key?(issue_data, "Assignee") do
          assignees =
            for %{"fullName" => full_name, "login" => username} <-
                  (issue_data["Assignees"] || issue_data["Assignee"])["value"],
                do: slack_link(YouTrack.base_url() <> "/users/#{username}", full_name)

          %{title: "Assignees", value: Enum.join(assignees, ","), short: true}
        end
      ],
      footer: "YouTrack",
      footer_icon: YouTrack.logo_url(),
      text:
        if Map.has_key?(issue_data, "description") do
          cutoff(issue_data["description"], max_text_size())
        end,
      title: "[#{issue_data["idReadable"]}] #{issue_data["summary"]}",
      title_link: YouTrack.base_url() <> "/issue/" <> issue_data["idReadable"],
      ts: issue_data["created"] / 1000
    }
  end
end
