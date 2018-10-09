alias Hermetic.{YouTrack, Slack}

defmodule Hermetic.Slash do
  @moduledoc ~S"""
  Handles Slack slash commands
  """

  @doc ~S"""
  Split a string into whitespace delimited or quoted parts.

      iex> split("Foo foon't \"bar bazn't\"")
      ["Foo", "foon't", "bar bazn't"]
  """
  @spec split(String.t()) :: [String.t()]
  def split(string) do
    do_split(String.trim_leading(string, " "), "", [], false)
  end

  # Any character after a backslash is taken literally
  @spec do_split(String.t(), String.t(), [String.t()], boolean) :: [String.t()]
  defp do_split(<<?\\, c, rest::binary>>, buf, acc, quoting),
    do: do_split(rest, <<buf::binary, c>>, acc, quoting)

  # Toggle quoting on double quote
  defp do_split(<<?", rest::binary>>, buf, acc, quoting),
    do: do_split(rest, buf, acc, !quoting)

  # Start a new segment after an unquoted space
  defp do_split(<<?\s, rest::binary>>, buf, acc, false),
    do: do_split(String.trim_leading(rest, " "), "", [buf | acc], false)

  # Any other character is simply copied
  defp do_split(<<c, rest::binary>>, buf, acc, quoting),
    do: do_split(rest, <<buf::binary, c>>, acc, quoting)

  # Finish string or raise if unclosed
  defp do_split(<<>>, "", acc, false), do: Enum.reverse(acc)
  defp do_split(<<>>, buf, acc, false), do: Enum.reverse([buf | acc])
  defp do_split(<<>>, _, _, _), do: raise("quoted string not closed")

  @doc ~S"""
  Translate a Slack user id to a YouTrack login name.
  """
  @spec translate_user_id(String.t()) :: String.t()
  def translate_user_id(slack_id) do
    YouTrack.cached_emails_to_logins()[Slack.user_profile(slack_id)["email"]]
  end

  @doc ~S"""
  Strip all xml tags from a string.
  """
  @spec strip_xml_tags(String.t()) :: String.t()
  def strip_xml_tags(xml) do
    String.replace(xml, ~r/\<[^\>]*\>/, "")
  end
end
