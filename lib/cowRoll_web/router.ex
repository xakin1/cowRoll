defmodule CowRollWeb.Router do
  use CowRollWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CowRollWeb do
    pipe_through :api
<<<<<<< Updated upstream
    get "/command", ApiCommandController, :get
    post "/command", ApiCommandController, :parse_command
=======
    post "/code", CodeController, :run_code
    get "/file/:id", CodeController, :get_files
    post "/saveCode/:id", CodeController, :save_code
    post "/compile", CodeController, :compile_code
    options "/*path", CorsManagement, :handle_options
>>>>>>> Stashed changes
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
