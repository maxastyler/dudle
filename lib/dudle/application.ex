defmodule Dudle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Dudle.Repo,
      # Start the Telemetry supervisor
      DudleWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Dudle.PubSub},
      # Start the Endpoint (http/https)
      DudleWeb.Endpoint
      # Start a worker by calling: Dudle.Worker.start_link(arg)
      # {Dudle.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dudle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DudleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
