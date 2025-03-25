# defmodule LiveviewChatWeb.MessageLive do
#   use LiveviewChatWeb, :live_view
#   alias LiveviewChat.Message
#   alias LiveviewChat.Presence
#   alias LiveviewChat.PubSub
#   # run authentication on mount
#   on_mount LiveviewChatWeb.AuthController

#   @presence_topic "liveview_chat_presence"

#   # def mount(_params, _session, socket) do
#   #   if connected?(socket) do
#   #     Message.subscribe()

#   #     {id, name} =
#   #       if Map.has_key?(socket.assigns, :person) do
#   #         {socket.assigns.person.id, socket.assigns.person.givenName}
#   #       else
#   #         {socket.id, "guest"}
#   #       end

#   #     {:ok, _} = Presence.track(self(), @presence_topic, id, %{name: name})
#   #     Phoenix.PubSub.subscribe(PubSub, @presence_topic)
#   #   end

#   #   changeset =
#   #     if Map.has_key?(socket.assigns, :person) do
#   #       Message.changeset(%Message{}, %{"name" => socket.assigns.person.givenName})
#   #     else
#   #       Message.changeset(%Message{}, %{})
#   #     end

#   #   messages = Message.list_messages() |> Enum.reverse()

#   #   {:ok,
#   #    assign(socket,
#   #      messages: messages,
#   #      changeset: changeset,
#   #      presence: get_presence_names()
#   #    ), temporary_assigns: [messages: []]}
#   # end
#   def mount(_params, _session, socket) do
#     if connected?(socket) do
#       Phoenix.PubSub.subscribe(LiveviewChat.PubSub, "dashboard:store123")
#       IO.puts("✅ Explicitly subscribed to dashboard:store123")
#     end

#     store_id = "store123"
#     #messages = Message.list_messages() |> Enum.reverse()
#     sessions = Message.list_chat_sessions_for_dashboard(store_id)

#     {:ok,
#      assign(socket,
#      store_id: store_id,
#      chat_sessions: sessions,
#        messages: [],
#        changeset: Message.changeset(%Message{}, %{}),
#        presence: get_presence_names()
#      )}
#   end

#   def render(assigns) do
#     LiveviewChatWeb.MessageView.render("messages.html", assigns)
#   end

#   # def handle_event("new_message", %{"message" => params}, socket) do
#   #   case Message.create_message(params) do
#   #     {:ok, _message} ->
#   #       changeset = Message.changeset(%Message{}, %{"name" => params["name"]})
#   #       {:noreply, assign(socket, changeset: changeset)}

#   #     {:error, changeset} ->
#   #       IO.inspect(changeset.errors, label: "⚠️ Changeset errors clearly")
#   #       {:noreply, assign(socket, changeset: changeset)}
#   #   end
#   # end
#   def handle_event("select_chat", %{"user_id" => user_id}, socket) do
#     messages = Message.list_messages_for_user(user_id, socket.assigns.store_id)

#     {:noreply,
#      assign(socket,
#        selected_user_id: user_id,
#        messages: messages,
#        changeset: Message.changeset(%Message{}, %{"user_id" => user_id})
#      )}
#   end

#   def handle_info({:message_created, message}, socket) do
#     IO.inspect(message, label: "✅ New message arrived clearly")
#     {:noreply, assign(socket, messages: [message | socket.assigns.messages])}
#   end

#   def handle_info(%{event: "presence_diff", payload: _diff}, socket) do
#     {
#       :noreply,
#       assign(socket, presence: get_presence_names())
#     }
#   end

#   defp get_presence_names() do
#     Presence.list(@presence_topic)
#     |> Enum.map(fn {_k, v} -> List.first(v.metas).name end)
#     |> group_names()
#   end

#   # return list of names and number of guests
#   defp group_names(names) do
#     loggedin_names = Enum.filter(names, fn name -> name != "guest" end)

#     guest_names =
#       Enum.count(names, fn name -> name == "guest" end)
#       |> guest_names()

#     if guest_names do
#       [guest_names | loggedin_names]
#     else
#       loggedin_names
#     end
#   end

#   defp guest_names(0), do: nil
#   defp guest_names(1), do: "1 guest"
#   defp guest_names(n), do: "#{n} guests"
# end
defmodule LiveviewChatWeb.MessageLive do
  use LiveviewChatWeb, :live_view
  alias LiveviewChat.Message
  alias LiveviewChat.Presence
  alias LiveviewChat.PubSub
  import Timex

  @presence_topic "liveview_chat_presence"
  # You can make this dynamic later if needed
  @store_id "store123"

  on_mount LiveviewChatWeb.AuthController

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PubSub, "dashboard:#{@store_id}")
      Phoenix.PubSub.subscribe(PubSub, @presence_topic)
    end

    sessions = Message.list_chat_sessions_for_dashboard(@store_id)

    {:ok,
     assign(socket,
       store_id: @store_id,
       chat_sessions: sessions,
       selected_user_id: nil,
       messages: [],
       changeset: Message.changeset(%Message{}, %{}),
       presence: get_presence_names()
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen">
      <!-- SIDEBAR -->
      <aside class="w-1/4 bg-gray-100 p-4 overflow-y-auto h-screen">
        <h2 class="font-bold mb-4">Chat Sessions</h2>
        <ul>
          <%= for session <- @chat_sessions do %>
            <li class="mb-2">
              <button
                phx-click="select_chat"
                phx-value-user_id={session.user_id}
                class={"w-full text-left px-4 py-2 rounded-lg " <>
                  if @selected_user_id == session.user_id, do: "bg-blue-200", else: "bg-white hover:bg-gray-200"}
              >
                <div class="font-semibold">User ID: {session.user_id}</div>
                <div class="text-sm text-gray-600 truncate">{session.last_message}</div>
                <div class="text-xs text-gray-400">{format_datetime(session.last_sent_at)}</div>
              </button>
            </li>
          <% end %>
        </ul>
      </aside>
      
    <!-- MAIN CHAT PANEL -->
      <main class="flex-1 flex flex-col justify-between p-6 bg-white">
        <%= if @selected_user_id do %>
          <ul id="msg-list" class="space-y-4 overflow-y-auto flex-1">
            <%= for message <- @messages do %>
              <li id={"msg-#{message.id}"} class="flex justify-between items-center">
                <div>
                  <b>{message.name} ({message.sender_type}):</b> {message.message}
                </div>
                <small class="text-gray-500 ml-2">
                  {format_datetime(message.inserted_at)}
                </small>
              </li>
            <% end %>
          </ul>

          <footer class="bg-slate-100 p-4 mt-4">
            <.form :let={f} for={@changeset} phx-submit="new_message">
              {hidden_input(f, :name, value: "Admin")}
              {hidden_input(f, :user_id, value: @selected_user_id)}
              {hidden_input(f, :store_id, value: @store_id)}
              {hidden_input(f, :sender_type, value: "admin")}

              {text_input(f, :message, placeholder: "Reply message", class: "border p-2 w-3/4")}
              {submit("Send", class: "ml-2 bg-blue-600 text-white px-4 py-2 rounded-lg")}
            </.form>
          </footer>
        <% else %>
          <p class="text-gray-600 text-center mt-10">
            Select a user from the sidebar to view messages.
          </p>
        <% end %>
      </main>
    </div>
    """
  end

  def handle_event("select_chat", %{"user_id" => user_id}, socket) do
    messages = Message.list_messages_for_user(user_id, socket.assigns.store_id)

    {:noreply,
     assign(socket,
       selected_user_id: user_id,
       messages: messages,
       changeset:
         Message.changeset(%Message{}, %{
           "name" => "Admin",
           "user_id" => user_id,
           "store_id" => socket.assigns.store_id,
           "sender_type" => "admin"
         })
     )}
  end

  def handle_event("new_message", %{"message" => params}, socket) do
    case Message.create_message(params) do
      {:ok, _message} ->
        changeset =
          Message.changeset(%Message{}, %{
            "name" => "Admin",
            "user_id" => socket.assigns.selected_user_id,
            "store_id" => socket.assigns.store_id,
            "sender_type" => "admin",
            # clean message input
            "message" => ""
          })

        {:noreply, assign(socket, changeset: changeset)}

      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "⚠️ Changeset errors")
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_info({:message_created, message}, socket) do
    if message.user_id == socket.assigns.selected_user_id do
      {:noreply, assign(socket, messages: socket.assigns.messages ++ [message])}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, presence: get_presence_names())}
  end

  defp format_datetime(nil), do: ""
  defp format_datetime(dt), do: Timex.format!(dt, "{YYYY}-{0M}-{0D} {h12}:{0m} {AM}")

  defp get_presence_names do
    Presence.list(@presence_topic)
    |> Enum.map(fn {_k, v} -> List.first(v.metas).name end)
    |> group_names()
  end

  defp group_names(names) do
    logged_in = Enum.filter(names, &(&1 != "guest"))
    guests = Enum.count(names, &(&1 == "guest")) |> guest_names()
    if guests, do: [guests | logged_in], else: logged_in
  end

  defp guest_names(0), do: nil
  defp guest_names(1), do: "1 guest"
  defp guest_names(n), do: "#{n} guests"
end
