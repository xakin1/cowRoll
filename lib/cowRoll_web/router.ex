defmodule CowRollWeb.Router do
  use CowRollWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: ["http://localhost:4321"], allow_credentials: true
  end

  pipeline :authenticated do
    plug CowRollWeb.Plug.Authenticate
  end

  pipeline :test do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  # Code
  scope "/api/code", CowRollWeb do
    pipe_through [:api, :authenticated]

    post "/compile", CodeController, :compile_code
    post "/run", CodeController, :run_code
  end

  scope "/api/file", CowRollWeb do
    pipe_through [:api, :authenticated]

    get "/", FileController, :get_files
    get "/:fileId", FileController, :get_file_by_id

    post "/create", FileController, :create_file
    post "/edit", FileController, :edit_file
    post "/save", FileController, :insert_content

    delete "/delete/:fileId", FileController, :remove_file
  end

  scope "/api/directory", CowRollWeb do
    pipe_through [:api, :authenticated]

    post "/create", DirectoryController, :create_directory
    post "/edit", DirectoryController, :edit_directory

    delete "/delete/:directoryId", DirectoryController, :remove_directory
  end

  # Users
  scope "/api", CowRollWeb do
    pipe_through :api
    post "/signUp", UserController, :register_user
    post "/login", UserController, :login_user
  end

  scope "/api", CowRollWeb do
    pipe_through [:api, :authenticated]
    delete "/deleteUser", UserController, :unregister_user
  end

  scope "/test", CowRollWeb do
    pipe_through :test
    delete "/reset", FileController, :delete_all
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
