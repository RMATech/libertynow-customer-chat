defmodule LiveviewChatWeb.MessageController do
  use LiveviewChatWeb, :controller
  alias LiveviewChat.Message

  # def index(conn, _params) do
  #   messages = Message.list_messages()
  #   json(conn, messages)
  # end
  # def index(conn, %{"user_id" => user_id}) do
  #     messages = LiveviewChat.Message.get_messages_for_user(user_id)
  #     json(conn, messages)
  # end
  def index(conn, %{"user_id" => user_id, "store_id" => store_id}) do
    messages = Message.list_messages_for_user(user_id, store_id)
    json(conn, messages)
  end

  def index(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters: user_id and store_id"})
  end

  def index(conn, _params) do
    messages = Message.list_messages()
    json(conn, messages)
  end

  def create(conn, params) do
    case Message.create_message(params) do
      {:ok, message} -> json(conn, message)
      {:error, changeset} -> json(conn, %{errors: changeset.errors})
    end
  end
end
