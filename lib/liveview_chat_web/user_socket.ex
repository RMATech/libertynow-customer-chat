defmodule LiveviewChatWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "chat:*", LiveviewChatWeb.ChatChannel

  ## Transports (optional depending on your Phoenix version)
  transport(:websocket, Phoenix.Transports.WebSocket)

  # Or use this if Phoenix >= 1.6
  # transport :websocket, Phoenix.Socket.Transport

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
