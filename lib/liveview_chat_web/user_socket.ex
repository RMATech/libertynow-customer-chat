defmodule LiveviewChatWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "chat:*", LiveviewChatWeb.ChatChannel

  ## Transports (optional depending on your Phoenix version)
  #transport(:websocket, Phoenix.Transports.WebSocket)

  # Or use this if Phoenix >= 1.6
  # transport :websocket, Phoenix.Socket.Transport

  def connect(%{"user_id" => user_id}, socket, _connect_info) do
    {:ok, assign(socket, :user_id, user_id)}
  end

  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
