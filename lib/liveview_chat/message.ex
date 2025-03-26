defmodule LiveviewChat.Message do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias LiveviewChat.Repo
  alias Phoenix.PubSub
  alias __MODULE__

  @derive {Jason.Encoder,
           only: [
             :id,
             :message,
             :name,
             :user_id,
             :store_id,
             :sender_type,
             :inserted_at,
             :updated_at
           ]}

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
    |> validate_required([:message, :user_id, :store_id, :sender_type])
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

  def list_chat_sessions_for_dashboard(store_id) do
    subquery =
    from(m in Message,
      where: m.store_id == ^store_id and m.sender_type in ^["user", "customer"],
      order_by: [desc: m.inserted_at],
      distinct: [m.user_id],
      select: %{
        user_id: m.user_id,
        last_message: m.message,
        last_sent_at: m.inserted_at
      }
    )


    Repo.all(subquery)
  end

  # def list_messages_for_user(user_id, store_id) do
  #   import Ecto.Query

  #   # Check if user has sent at least one message
  #   started_conversation? =
  #     from(m in Message,
  #       where: m.user_id == ^user_id and m.store_id == ^store_id and m.sender_type == "user",
  #       select: count(m.id)
  #     )
  #     |> Repo.one()

  #   if started_conversation? > 0 do
  #     # User started chat – return all messages related to them in this store
  #     from(m in Message,
  #       where: m.user_id == ^user_id and m.store_id == ^store_id,
  #       order_by: [asc: m.inserted_at]
  #     )
  #     |> Repo.all()
  #   else
  #     # User hasn't started chat yet – return empty list
  #     []
  #   end
  # end
  def list_messages_for_user(user_id, store_id) do
    import Ecto.Query
  
    from(m in Message,
      where: m.user_id == ^user_id and m.store_id == ^store_id,
      order_by: [asc: m.inserted_at]
    )
    |> Repo.all()
  end
  
  def subscribe() do
    PubSub.subscribe(LiveviewChat.PubSub, "dashboard:store123")
  end

  def notify({:ok, message} = result, event) do
    # Notify the dashboard
    Phoenix.PubSub.broadcast(
      LiveviewChat.PubSub,
      "dashboard:#{message.store_id}",
      {event, message}
    )

    # Notify the user (mobile app)
    Phoenix.PubSub.broadcast(
      LiveviewChat.PubSub,
      "liveview_chat:#{message.user_id}",
      {:message_created, message}
    )

    IO.inspect(message, label: "🚀 PubSub broadcasted message")

    result
  end

  def notify({:error, reason}, _event), do: {:error, reason}
end
