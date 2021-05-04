# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :dudle,
  ecto_repos: [Dudle.Repo]

# Configures the endpoint
config :dudle, DudleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "xp4Jh9+YRs6cIbUONb9F83BQeTdION4MfIiEu+5dxUNXpjGo6N3p8ZJ5DR+0wsbl",
  render_errors: [view: DudleWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Dudle.PubSub,
  live_view: [signing_salt: "MXAvgbnc"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
