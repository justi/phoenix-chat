defmodule Slackir.DeleteMessagesWorker do
  use GenServer

  @name __MODULE__

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def init([]) do
    {:ok, %{}}
  end

  def remove_messages() do
    #    let time = NaiveDateTime.add(NaiveDateTime.utc_now(), - 60, :second)
    #    spawn(:ets, :delete, [:disappearing_messages_table, {NaiveDateTime.utc_now(), payload["name"], payload["message"]}])
  end
end
