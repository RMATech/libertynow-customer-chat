defmodule LiveviewChatWeb.ChatChannel do
  use Phoenix.Channel
  alias LiveviewChat.Message
  alias Ecto.Changeset

  def join("chat:" <> store_id, %{"user_id" => user_id}, socket) do
    Phoenix.PubSub.subscribe(LiveviewChat.PubSub, "liveview_chat:#{user_id}")

    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:store_id, store_id)

    {:ok, socket}
  end

  def handle_in("new_msg", %{"message" => msg_body, "name" => name}, socket) do
    enriched_payload = %{
      "user_id" => socket.assigns.user_id,
      "store_id" => socket.assigns.store_id,
      "message" => msg_body,
      "name" => name,
      "sender_type" => "user"
    }

    case Message.create_message(enriched_payload) do
      {:ok, message} ->
        {:reply, {:ok, %{message: "Message sent"}}, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: translate_changeset_errors(changeset)}}, socket}
    end
  end

  def handle_info({:message_created, message}, socket) do
    broadcast!(socket, "new_msg", %{
      id: message.id,
      name: message.name,
      message: message.message,
      sender_type: message.sender_type
    })

    {:noreply, socket}
  end

  defp translate_changeset_errors(changeset) do
    Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
