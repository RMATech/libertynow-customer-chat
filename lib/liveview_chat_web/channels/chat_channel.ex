defmodule LiveviewChatWeb.ChatChannel do
  use Phoenix.Channel
  alias LiveviewChat.Message
  alias Ecto.Changeset

#   def join("chat:" <> store_id, _payload, %{params: %{"user_id" => user_id}} = socket) do
#     Phoenix.PubSub.subscribe(LiveviewChat.PubSub, "liveview_chat:#{user_id}")

#     socket =
#       socket
#       |> assign(:user_id, user_id)
#       |> assign(:store_id, store_id)

#     {:ok, socket}
#   end
    def join("chat:" <> store_id, payload, socket) do   
        user_id =
        payload["user_id"] ||
            socket.assigns[:user_id] ||
            socket.params["user_id"]
    
        if user_id do
        Phoenix.PubSub.subscribe(LiveviewChat.PubSub, "liveview_chat:#{user_id}")
    
        socket =
            socket
            |> assign(:user_id, user_id)
            |> assign(:store_id, store_id)
    
        {:ok, socket}
        else
        {:error, %{reason: "missing user_id"}}
        end
    end
  
    def handle_in("new_msg", %{"message" => msg_body, "name" => name, "user_id" => user_id, "store_id" => store_id, "sender_type" => sender_type}, socket) do
        enriched_payload = %{
        "user_id" => socket.assigns.user_id,
        "store_id" => socket.assigns.store_id,
        "message" => msg_body,
        "name" => name,
        "sender_type" => sender_type
        }

    case Message.create_message(enriched_payload) do
      {:ok, _message} ->
        {:reply, {:ok, %{message: "Message sent"}}, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: translate_changeset_errors(changeset)}}, socket}
    end
  end

  def handle_info({:message_created, message}, socket) do
    IO.puts("📥 [ChatChannel] handle_info triggered")
    IO.inspect(message, label: "📥 B2C Message from PubSub")
    broadcast!(socket, "new_msg", %{
        id: message.id,
        message: message.message,
        name: message.name,
        sender_type: message.sender_type,
        user_id: message.user_id,
        store_id: message.store_id,
        inserted_at: message.inserted_at
    })

    {:noreply, socket}
  end

  defp translate_changeset_errors(changeset) do
    Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
