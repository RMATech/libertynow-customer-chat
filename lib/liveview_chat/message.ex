defmodule LiveviewChat.Message do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias LiveviewChat.Repo
  alias Phoenix.PubSub
  alias __MODULE__
  
  schema "messages" do
    field :message, :string
    field :name, :string
    field :user_id, :string     
    field :store_id, :string     
    field :sender_type, :string
    timestamps()
  end


  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:name, :message, :user_id, :store_id, :sender_type])
    |> validate_required([:message, :sender_type])
    |> validate_length(:message, min: 2)
  end

  def create_message(attrs) do
    %Message{}
    |> changeset(attrs)
    |> Repo.insert()
    |> notify(:message_created)
  end

  def list_messages do
    Message
    |> limit(20)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def subscribe() do
    PubSub.subscribe(LiveviewChat.PubSub, "liveview_chat")
  end

  def notify({:ok, message}, event) do
    Phoenix.PubSub.broadcast(LiveviewChat.PubSub, "liveview_chat", {event, message})
    {:ok, message}
  end

  def notify({:error, reason}, _event), do: {:error, reason}
end
