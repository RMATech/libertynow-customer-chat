defmodule LiveviewChatWeb.AdminChatLive do
  use LiveviewChatWeb, :live_view
  alias LiveviewChat.Message

  # def mount(_params, _session, socket) do
  #   if socket.assigns[:loggedin] do
  #     Phoenix.PubSub.subscribe(LiveviewChat.PubSub, "chat:#{@store_id}")
  #     messages = Message.list_messages()
  #     grouped = Enum.group_by(messages, & &1.user_id)

  #     {:ok,
  #      assign(socket,
  #        messages_by_user: grouped,
  #        message_input: "",
  #        current_user_id: nil
  #      )}
  #   else
  #     {:ok, socket}
  #   end
  # end
  def mount(_params, _session, socket) do
    if socket.assigns[:loggedin] do
      Phoenix.PubSub.subscribe(LiveviewChat.PubSub, "dashboard:store123")
      messages = Message.list_messages() |> Enum.group_by(& &1.user_id)

      IO.puts("Subscribed to dashboard:store123 ✅")

      {:ok,
       assign(socket,
         messages_by_user: messages,
         message_input: "",
         current_user_id: nil
       )}
    else
      {:ok, socket}
    end
  end

  def handle_event("select_user", %{"user_id" => user_id}, socket) do
    {:noreply, assign(socket, current_user_id: user_id)}
  end

  def handle_event(
        "send_message",
        %{"message" => text},
        %{assigns: %{current_user_id: user_id}} = socket
      ) do
    Message.create_message(%{
      "user_id" => user_id,
      # optionally dynamic later
      "store_id" => "store123",
      "message" => text,
      "name" => "Support Agent",
      "sender_type" => "admin"
    })

    messages = Message.list_messages() |> Enum.group_by(& &1.user_id)

    {:noreply,
     assign(socket,
       messages_by_user: messages,
       message_input: ""
     )}
  end

  # def handle_info({:new_message, message}, socket) do
  #   IO.inspect(message, label: "New incoming message")
  #   # Update the grouped message list
  #   updated_messages_by_user =
  #     socket.assigns.messages_by_user
  #     |> Map.update(message.user_id, [message], fn msgs -> [message | msgs] end)

  #   {:noreply, assign(socket, messages_by_user: updated_messages_by_user)}
  # end
  def handle_info({:message_created, message}, socket) do
    IO.inspect(message, label: "New incoming message")

    updated_messages_by_user =
      socket.assigns.messages_by_user
      |> Map.update(message.user_id, [message], fn msgs -> [message | msgs] end)

    {:noreply, assign(socket, messages_by_user: updated_messages_by_user)}
  end
end
