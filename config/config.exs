# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Configures the endpoint
config :allcoins, AllcoinsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "zoqthAmzeq2tPd9jTyZEJHdmTQL6gKIDaJvoFGVUSU2fzcYWsS58K2oYFGXpxoZ2",
  render_errors: [view: AllcoinsWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Allcoins.PubSub,
  live_view: [signing_salt: "aXYcIZ80"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
