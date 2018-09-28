use Mix.Config

config :hermetic, Hermetic,
  cowboy_options: [port: 59468]

config :hermetic, Hermetic.EventAPI,
  max_attachments: 3

config :hermetic, Hermetic.Router,
  slack_secrets: ["00000000000000000000000000000000"]

config :hermetic, Hermetic.Slack,
  token: "xoxa-0000000000-000000000000-000000000000-00000000000000000000000000000000"

# YouTrack's base URL and user token
config :hermetic, Hermetic.YouTrack,
  base_url: "https://youtrack.example.com",
  token: "perm:00000000000000000000000000000000000000000000000000000000000000000000"
