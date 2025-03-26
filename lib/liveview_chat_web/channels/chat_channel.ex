defmodule LiveviewChatWeb.ChatChannel do
  use Phoenix.Channel
  alias LiveviewChat.Message
  alias Ecto.Changeset

  # When a client (e.g., a phone app) joins the "chat:lobby" channel,
  # we subscribe this channel process to the "liveview_chat" topic.
  # This allows the channel to receive broadcasts of new messages created
  # (from both web and phone clients) and relay them to the connected client.
  def join("chat:lobby", _payload, socket) do
    :ok = Phoenix.PubSub.subscribe(LiveviewChat.PubSub, "liveview_chat")
    {:ok, socket}
  end

  # This function handles incoming "new_msg" events from clients.
  # The payload contains the message data sent from the client.
  # We attempt to create a new message in the database.
  def handle_in("new_msg", payload, socket) do

  # Check if the socket already has a user_id assigned.
  # If not, generate a new unique user_id and assign it to the socket.
    {user_id, socket} =
      case socket.assigns[:user_id] do
        nil ->
          new_id = Ecto.UUID.generate()
          {new_id, assign(socket, :user_id, new_id)}
        existing ->
          {existing, socket}
    end

    payload =
      payload
      |> Map.put("sender_type", "user")
      |> Map.put("user_id", user_id)
      |> Map.put("store_id", "Hegna")
      |> Map.put("name", "Hegna-" <> user_id)   

    case Message.create_message(payload) do
      {:ok, _message} ->
        {:reply, {:ok, %{message: "Message created successfully"}}, socket}

      {:error, changeset} ->
        errors = translate_changeset_errors(changeset)
        {:reply, {:error, %{errors: errors}}, socket}
    end
  end

   # This function handles incoming broadcasts on the "liveview_chat" topic.
  # When a new message is broadcast (as {:message_created, message}),
  # this function relays it to all clients connected on "chat:lobby" by
  # broadcasting a "new_msg" event with the message data.
  def handle_info({:message_created, message}, socket) do
    broadcast!(socket, "new_msg", %{
      id: message.id,
      name: message.name,
      message: message.message,
      sender_type: message.sender_type
    })

    {:noreply, socket}
  end

  # Helper function to convert Ecto changeset errors into a simple map.
  # This makes the errors JSON-friendly so that they can be sent as a response.
  defp translate_changeset_errors(changeset) do
    Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
