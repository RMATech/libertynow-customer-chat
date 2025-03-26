defmodule LiveviewChatWeb.MessageLive do
  use LiveviewChatWeb, :live_view
  alias LiveviewChat.Message
  alias LiveviewChat.Presence
  alias LiveviewChat.PubSub

  # Run authentication on mount
  on_mount LiveviewChatWeb.AuthController

  @presence_topic "liveview_chat_presence"

  # mount/3: Called when the LiveView is first rendered.
  # This sets up the initial state and subscriptions.
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Message.subscribe()

      # Determine the user’s ID and name.
      # If the socket has a :person assigned (authenticated user), use its id and givenName;
      # otherwise, default to a "guest".
      {id, name} =
        if Map.has_key?(socket.assigns, :person) do
          {socket.assigns.person.id, socket.assigns.person.givenName}
        else
          {socket.id, "guest"}
        end

      {:ok, _} = Presence.track(self(), @presence_topic, id, %{name: name})
      Phoenix.PubSub.subscribe(PubSub, @presence_topic)
    end

    changeset =
      if Map.has_key?(socket.assigns, :person) do
        Message.changeset(%Message{}, %{"name" => socket.assigns.person.givenName})
      else
        Message.changeset(%Message{}, %{})
      end

    # Start with a blank chat for a new session
    messages = []

    {:ok,
     assign(socket,
       messages: messages,
       changeset: changeset,
       presence: get_presence_names()
     )}
  end

  # render/1: Renders the view using the "messages.html" template.
  def render(assigns) do
    LiveviewChatWeb.MessageView.render("messages.html", assigns)
  end

  # handle_event/3: Called when the admin (web) submits a new message via the form.
  # The form sends an event "new_message" with the message parameters.
  def handle_event("new_message", %{"message" => params}, socket) do
    # If your schema uses :name (not :sender), do:
    params =
      params
      |> Map.put("name", "admin")
      |> Map.put("sender_type", "admin")

    # Attempt to create a new message in the database.
    case Message.create_message(params) do
      {:ok, _message} ->
        # Reset the form’s changeset to clear the input box
        new_changeset = Message.changeset(%Message{}, %{})
        {:noreply, assign(socket, changeset: new_changeset)}

      {:error, changeset} ->
        # Show validation errors if needed
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # handle_info/2: Receives broadcasted new messages.
  # When a new message is broadcast as {:message_created, message},
  # this function appends it to the list of messages in the LiveView.
  def handle_info({:message_created, message}, socket) do
    new_messages = socket.assigns.messages ++ [message]
    IO.inspect(new_messages, label: "New Messages After Append")
    {:noreply, assign(socket, messages: new_messages)}
  end

  # handle_info/2: Listens for presence diff events so the guest list can be updated.
  def handle_info(%{event: "presence_diff", payload: _diff}, socket) do
    {:noreply, assign(socket, presence: get_presence_names())}
  end

  # Helper function to get the list of current user names from the presence data.
  defp get_presence_names() do
    Presence.list(@presence_topic)
    |> Enum.map(fn {_k, v} -> List.first(v.metas).name end)
    |> group_names()
  end

  # group_names/1: Groups names for display purposes.
  # It filters out "guest" names and, if there are guests, returns a guest count
  # followed by the logged-in user names.
  defp group_names(names) do
    loggedin_names = Enum.filter(names, fn name -> name != "guest" end)
    guest_names =
      Enum.count(names, fn name -> name == "guest" end)
      |> guest_names()

    if guest_names do
      [guest_names | loggedin_names]
    else
      loggedin_names
    end
  end

  defp guest_names(0), do: nil
  defp guest_names(1), do: "1 guest"
  defp guest_names(n), do: "#{n} guests"
end