defmodule Dudle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # start the game server registry and supervisor
      {Registry, keys: :unique, name: Dudle.GameRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: Dudle.GameSupervisor},
      # Start the Ecto repository
      Dudle.Repo,
      # Start the Telemetry supervisor
      DudleWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Dudle.PubSub},
      # Start the Endpoint (http/https)
      DudleWeb.Endpoint,
      # Start the presence server
      Dudle.Presence
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
