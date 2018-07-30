use Mix.Config

# Slack bot token: https://api.slack.com/bot-users
config :hermetic, Hermetic.SlackBot,
  token: "xoxb-0000000000-000000000000-aaaaaaaaaaaaaaaaaaaaaaaa"

# YouTrack's base URL and user token
config :hermetic, Hermetic.YouTrack,
  base_url: "https://issues.serokell.io",
  token: "perm:d2h5IGRpZCB5b3UgZGVjb2RlIHRoaXM/IHBsZWFzZSBkbyBub3QgZGVjb2RlIGluIHRo"
