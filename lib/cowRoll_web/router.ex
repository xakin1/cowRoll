defmodule CowRollWeb.Router do
  use CowRollWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  pipeline :authenticated do
    plug CowRollWeb.Plug.Authenticate
  end

  pipeline :test do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  scope "/api", CowRollWeb do
    pipe_through [:api, :authenticated]

    # Code
    get "/file", CodeController, :get_files
    get "/file/:fileId", CodeController, :get_file_by_id

    post "/code", CodeController, :run_code
    post "/createFile", CodeController, :create_file
    post "/createDirectory", CodeController, :create_directory
    post "/editFile", CodeController, :edit_file
    post "/editDirectory", CodeController, :edit_directory
    post "/insertContent", CodeController, :insert_content
    post "/compile", CodeController, :compile_code

    delete "/deleteFile/:fileId", CodeController, :remove_file
    delete "/deleteDirectory/:directoryId", CodeController, :remove_directory

    options "/*path", CorsManagement, :handle_options
  end

  scope "/api", CowRollWeb do
    pipe_through :api
    # Users
    post "/signUp", UserController, :register_user
    post "/login", UserController, :login_user
  end

  scope "/test", CowRollWeb do
    pipe_through :test
    delete "/reset", CodeController, :delete_all
    options "/*path", CorsManagement, :handle_options
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:cowRoll, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: CowRollWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
