defmodule CowRoll.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CowRollWeb.Telemetry,
      {Phoenix.PubSub, name: CowRoll.PubSub},
      {Finch, name: CowRoll.Finch},
      {CowRollWeb.Endpoint, []},
      {Mongo, Application.get_env(:cowRoll, CowRoll.Mongo)}
    ]

    opts = [strategy: :one_for_one, name: CowRoll.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CowRollWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
