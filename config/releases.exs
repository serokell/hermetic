import Config
# https://github.com/elixir-lang/elixir/issues/9338
File.chmod(System.get_env("RELEASE_SYS_CONFIG") <> ".config", 0o644)

config :hermetic, Hermetic,
  cowboy_options: [port: String.to_integer(System.get_env("HERMETIC_PORT"))]

config :hermetic, Hermetic.Slash.Deploy,
  default_ref: "production",
  default_env: "staging"

config :hermetic, Hermetic.Router,
  slack_secrets: [System.get_env("HERMETIC_SLACK_SECRET")]

config :hermetic, Hermetic.Slack,
  token: System.get_env("HERMETIC_SLACK_TOKEN")

config :hermetic, Hermetic.Github,
  token: System.get_env("HERMETIC_GH_TOKEN")

# YouTrack's base URL and user token
config :hermetic, Hermetic.YouTrack,
  base_url: "https://issues.serokell.io",
  token: System.get_env("HERMETIC_YT_TOKEN")
