![Logo](logo.svg)

# Hermetic

Hermetic is a Slack bot for YouTrack integration. It has the following features:

- Reply with an issue overview attachment whenever an issue code is mentioned.
- Add a new YouTrack issue right from the chat.
- Run an arbitrary YouTrack command on an issue right from the chat.

## Build instructions

Run `nix-shell` in the root of the repo to pull in elixir. Run `mix deps.get` to
pull in dependencies and install hex if asked. Run `iex -S mix` to get a repl,
`mix test` to check no tests are breaking and `mix dialyzer` to do type
checking. The last one takes a while on the first run.

## Usage

### Adding Hermetic to the Slack

Copy `config/example-config.exs` to `config/config.exs` and fill in the secrets
(Slack, Youtrack and Github API tokens).

[Set up a Slack app](https://api.slack.com/slack-apps) and create two slash
commands that point to `https://yourdomain.tld/yt-add` and
`https://yourdomain.tld/yt-cmd`. Make sure to enable user escaping so Hermetic
can translate Slack users (by email) to YouTrack users. You can use `nginx` for
example to handle `https` and routing.

### Using the bot

Run those slash commands in a chat with Hermetic:

- `/yt-add ProjectID [@assignee] [#tag] Title text` Add a YouTrack issue. A link to a previous message in the chat is added to an issue description.
- `/yt-cmd issue-ID youtrack command` Run a YouTrack command on an issue.

Also, Hermetic will automatically reply to any message containing `issue-ID` (e.
g. `AD-150`) with a link to this issue.

## Issue tracker

We use [YouTrack](https://issues.serokell.io/issues/INT) as our issue tracker.
You can login using your GitHub account to leave a comment or create a new issue.

## About Serokell

Hermetic is maintained by [Serokell](https://serokell.io/).

We love open source software.
See which [services](https://serokell.io/#services) we provide and [drop us a line](mailto:hi@serokell.io) if you are interested.
