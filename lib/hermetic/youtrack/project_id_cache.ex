alias Hermetic.YouTrack

defmodule Hermetic.YouTrack.ProjectIdCache do
  import ConfigMacro
  config :hermetic, update_interval: 1000 * 60 * 5

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def schedule_update(msec \\ 1) do
    Process.send_after(self(), :update, msec)
  end

  def init([]) do 
    {:ok, %{data: [], timer: schedule_update()}}
  end

  def handle_call(:get, _, state) do
    {:reply, state.data, state}
  end

  def handle_info(:update, %{timer: old_timer}) do
    Process.cancel_timer(old_timer)
    new_timer = update_interval() |> schedule_update()
    {:noreply, %{data: YouTrack.project_ids(), timer: new_timer}}
  end

  def get do
    GenServer.call(__MODULE__, :get)
  end
end
