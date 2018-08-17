alias Hermetic.YouTrack

defmodule Hermetic.YouTrack.ProjectIdCache do
  @moduledoc """
    Polling cache that fetches available YouTrack project IDs
    every `refresh_interval()`.
  """

  import ConfigMacro
  config :hermetic, refresh_interval: 1000 * 60 * 5

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
    Schedule a cache refresh in `n` milliseconds.
  """
  def schedule_refresh(n \\ 1) do
    Process.send_after(self(), :refresh, n)
  end

  def init([]) do
    {:ok, %{data: [], timer: schedule_refresh()}}
  end

  def handle_call(:get, _, state) do
    {:reply, state.data, state}
  end

  def handle_info(:refresh, %{timer: old_timer}) do
    Process.cancel_timer(old_timer)
    new_timer = refresh_interval() |> schedule_refresh()
    {:noreply, %{data: YouTrack.project_ids(), timer: new_timer}}
  end

  def get do
    GenServer.call(__MODULE__, :get)
  end
end
