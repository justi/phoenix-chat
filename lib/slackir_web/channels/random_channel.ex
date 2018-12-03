defmodule Slackir.RandomChannel do
  use Slackir.Web, :channel

  require IEx
  import Ecto

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
    messages = refresh_messages()

    push(socket, "messages_history", %{messages: messages})
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  def refresh_messages() do
    messages =
      Slackir.Conversations.list_messages()
      |> Enum.map(
           &%{message: &1.message, name: &1.name, disappear: false, timestamp: &1.inserted_at}
         )

    messages_ets =
      :ets.match_object(:disappearing_messages_table, {:_, :_, :_, :_})
      |> Enum.map(
           &%{
             message: elem(&1, 2),
             name: elem(&1, 1),
             disappear: true,
             timestamp: elem(&1, 0),
             id: elem(&1, 3)
           }
         )
    messages =
      (messages ++ messages_ets)
      |> Enum.sort(&(NaiveDateTime.compare(&1.timestamp, &2.timestamp) == :lt))
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (random:lobby).

  def handle_in("shout", %{"disappear" => false} = payload, socket) do
    spawn(Slackir.Conversations, :create_message, [payload])
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  def handle_in("shout", %{"disappear" => true} = payload, socket) do
    ttl = 30
    expiration = :os.system_time(:seconds) + ttl
    time = NaiveDateTime.utc_now()
    payload = Map.put(payload, "id", Ecto.UUID.generate)

    spawn(:ets, :insert, [
      :disappearing_messages_table,
      {time, payload["name"], payload["message"], payload["id"]}
    ])

    handle_disappearing(socket, time, payload["id"])

    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  def handle_disappearing(socket, time, id) do
    spawn(fn ->
      :timer.sleep(10000)
      :ets.delete(:disappearing_messages_table, time)
      broadcast(socket, "message_delete", %{id: id})
    end)
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
