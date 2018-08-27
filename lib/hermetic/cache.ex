defmodule Hermetic.Cache do
  @moduledoc ~S"""
  Generic cache for given function that is periodically refreshed.
  """

  use GenServer

  @default_interval 1000 * 60 * 5

  def child_spec(args, options \\ []) do
    %{
      # FIXME: Temporary hack to allow multiple Caches. Yegor will fix this
      id: options[:name],
      start: {GenServer, :start_link, [__MODULE__, args, options]}
    }
  end

  def init(args) do
    function = args.function
    interval = Map.get(args, :interval, @default_interval)

    {:ok,
     %{
       data: apply(function, []),
       function: function,
       interval: interval,
       timer: schedule_refresh(self(), interval)
     }}
  end

  def handle_call(:get, _, state) do
    {:reply, state.data, state}
  end

  def handle_info(:refresh, state) do
    Process.cancel_timer(state.timer)

    update = %{
      data: apply(state.function, []),
      timer: schedule_refresh(self(), state.interval)
    }

    {:noreply, Map.merge(state, update)}
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  @doc ~S"""
  Schedule a cache refresh in `n` milliseconds.
  """
  def schedule_refresh(pid, n \\ 1) do
    Process.send_after(pid, :refresh, n)
  end
end
