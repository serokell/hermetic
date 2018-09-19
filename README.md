![Logo](logo.svg)

# Hermetic

Hermetic is a Slack bot for YouTrack integration. It has the following features:

- Reply with an issue overview attachment whenever an issue code is mentioned.
- Slash commands:
	- `/yt-add ProjectID [@assignee] [#tag] Title text` Add a YouTrack issue.
	- `/yt-cmd issue-ID youtrack command` Run a YouTrack command on an issue.

## Contributing

Copy `config/example-config.exs` to `config/config.exs` and fill in the secrets.

Run `nix-shell` in the root of the repo to pull in elixir. Run `mix deps.get` to
pull in dependencies and install hex if asked. Run `iex -S mix` to get a repl,
`mix test` to check no tests are breaking and `mix dialyzer` to do type
checking. The last one takes a while on the first run.
