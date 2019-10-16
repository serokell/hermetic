import Config

config :hermetic, Hermetic,
  cowboy_options: [port: 8080]


config :hermetic, Hermetic.Slash.Deploy,
  default_ref: "production",
  default_env: "staging"

config :hermetic, Hermetic.EventAPI,
  max_attachments: 3

config :hermetic, Hermetic.Attachment,
  max_text_size: 280

config :hermetic, Hermetic.YouTrack,
  base_url: "https://issues.serokell.io"

config :logger, :console,
  format: "$metadata[$level] $message\n",
  metadata: [:request_id]

if File.exists?("config/dev.secret.exs") do
  import_config "dev.secret.exs"
else
  IO.puts(
    "Please copy config/example-config.exs to config/dev.secret.exs and provide local configuration"
  )
end
