defmodule LiveviewChatWeb.Router do
  use LiveviewChatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LiveviewChatWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authOptional, do: plug(AuthPlugOptional)

  scope "/", LiveviewChatWeb do
    pipe_through [:browser, :authOptional]

    live_session :admin_session, on_mount: {LiveviewChatWeb.AuthController, :default} do
      live "/", MessageLive
    end
    get "/login", AuthController, :login
    get "/logout", AuthController, :logout
  end

  
  scope "/api", LiveviewChatWeb do
    pipe_through :api
    resources "/messages", MessageController, only: [:index, :create]
  end
end
