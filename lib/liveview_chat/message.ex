defmodule LiveviewChat.Message do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias LiveviewChat.Repo
  alias Phoenix.PubSub
  alias __MODULE__
  
  # Schema definition for the "messages" table.
  # Each message stores the text (in :message) and the sender's identifier (in :name).
  schema "messages" do
    field :message, :string
    field :name, :string
    timestamps()
  end

  # changeset/2: Builds a changeset for a message using the provided attributes.
  # It casts the attributes for :name and :message, requires them, and validates the message length.
  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:name, :message])
    |> validate_required([:name, :message])
    |> validate_length(:message, min: 2)
  end

  # create_message/1: 
  # - Builds a changeset from the given attributes.
  # - Inserts the message into the database using Repo.insert().
  # - If successful, it calls notify/2 to broadcast the new message on the "liveview_chat" topic.
  # The function returns {:ok, message} on success or {:error, reason} on failure.
  def create_message(attrs) do
    %Message{}
    |> changeset(attrs)
    |> Repo.insert()
    |> notify(:message_created)
  end

  # list_messages/0:
  # Retrieves the 20 most recent messages, ordered by the time they were inserted (newest first).
  def list_messages do
    Message
    |> limit(20)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  # subscribe/0:
  # Allows a process (for example, a LiveView) to subscribe to the "liveview_chat" topic.
  # This subscription lets the process receive broadcasts of new messages.
  def subscribe() do
    PubSub.subscribe(LiveviewChat.PubSub, "liveview_chat")
  end

  # notify/2:
  # - If the message insertion was successful (i.e., the result is {:ok, message}),
  #   this function broadcasts the message on the "liveview_chat" topic with the given event.
  # - It then returns {:ok, message} so that the caller can pattern match on it.
  def notify({:ok, message}, event) do
    Phoenix.PubSub.broadcast(LiveviewChat.PubSub, "liveview_chat", {event, message})
    {:ok, message}
  end

  def notify({:error, reason}, _event), do: {:error, reason}
end
