# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :hound, driver: "phantomjs"

# Configures the endpoint
config :unsolvedmm, UnsolvedmmWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "cGGo3BWdXBTM9ABbzlebWhwc4E0SNvvniNSeYAm+qI5uCPUusx2Jdcziq46bkJWm",
  render_errors: [view: UnsolvedmmWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Unsolvedmm.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true,
  live_view: [
    signing_salt: "bxF5OGDBXv+vtrfDKXKA41X7bQ3qvuEqUvDzdOhkbu7LNOVYjbuUcDWaa2zNdQh/"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :mnesia, dir: '.mnesia/#{Mix.env}/#{node()}'  

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
