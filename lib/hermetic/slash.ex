alias Hermetic.{YouTrack, Slack}

defmodule Hermetic.Slash do
  @moduledoc ~S"""
  Handles Slack slash commands
  """

  @doc ~S"""
  Translate a Slack user id to a YouTrack login name.
  """
  @spec translate_user_id(String.t()) :: String.t()
  def translate_user_id(slack_id) do
    YouTrack.emails_to_logins()[Slack.user_email(slack_id)]
  end

  @doc ~S"""
  Strip all xml tags from a string.
  """
  @spec strip_xml_tags(String.t()) :: String.t()
  def strip_xml_tags(xml) do
    String.replace(xml, ~r/\<[^\>]*\>/, "")
  end
end
