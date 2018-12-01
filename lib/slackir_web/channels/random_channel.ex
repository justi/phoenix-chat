defmodule Slackir.RandomChannel do
  use Slackir.Web, :channel

  require IEx

  def join("random:lobby", payload, socket) do
    IO.inspect("JOIN")

    if authorized?(payload) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    messages =
      Slackir.Conversations.list_messages()
      |> Enum.map(
        &%{message: &1.message, name: &1.name, disappear: false, timestamp: &1.inserted_at}
      )

    messages_ets =
      :ets.match(:disappearing_messages_table, {:"$1", :"$2", :"$3"})
      |> Enum.map(
        &%{
          message: Enum.at(&1, 2),
          name: Enum.at(&1, 1),
          disappear: true,
          timestamp: Enum.at(&1, 0)
        }
      )

    messages =
      (messages ++ messages_ets)
      |> Enum.sort(&(NaiveDateTime.compare(&1.timestamp, &2.timestamp) == :lt))

    push(socket, "messages_history", %{messages: messages})
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (random:lobby).

  def handle_in("shout", %{"disappear" => false} = payload, socket) do
    IO.inspect("siema")
    spawn(Slackir.Conversations, :create_message, [payload])
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  def handle_in("shout", %{"disappear" => true} = payload, socket) do
    ttl = 30
    expiration = :os.system_time(:seconds) + ttl
    time = NaiveDateTime.utc_now()

    v = :ets.insert(:disappearing_messages_table, {time, payload["name"], payload["message"]})
    IEx.pry()

    spawn(:ets, :insert, [
      :disappearing_messages_table,
      {time, payload["name"], payload["message"]}
    ])

    delete_and_refresh(time)
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  def handle_in("shout", payload, socket) do
    {:noreply, socket}
  end

  def delete_and_refresh(time) do
    spawn(fn ->
      :timer.sleep(60000)
      :ets.delete(:disappearing_messages_table, time)
    end)
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
