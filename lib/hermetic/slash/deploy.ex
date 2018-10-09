alias Hermetic.Github

defmodule Hermetic.Slash.Deploy do
  @moduledoc ~S"""
  Handle `/deploy user/repo[@ref] [to target]` command.
  """

  import Hermetic.Slash
  import Plug.Conn

  use Plug.ErrorHandler

  def init([]), do: []

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, 200, "Wrong syntax, use: /deploy user/repo[@ref] [to target]")
  end

  @doc ~S"""
  Parse a /deploy command into an owner, repository, git ref and deployment
  environment.
  """
  @spec parse(String.t()) :: {String.t(), String.t(), String.t(), String.t()}
  def parse(command) do
    [repo | command] = split(command)

    [repo, ref] =
      if String.contains?(repo, "@") do
        String.split(repo, "@")
      else
        [repo, "production"]
      end

    env =
      case command do
        [] -> "production"
        ["to", env] -> env
      end

    [owner, repo] = String.split(repo, "/")
    {owner, repo, ref, env}
  end

  def call(conn, []) do
    {owner, repo, ref, env} = parse(conn.body_params["text"])
    result = Github.deploy(owner, repo, ref, env)

    response =
      if result.status_code == 201 do
        "Deployed #{owner}/#{repo}@#{ref} to #{env}."
      else
        result.body["message"]
      end

    send_resp(conn, 200, response)
  end
end
