# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Личный ключ доступа к GitHub
# Example: config :gitsome, :git_hub_key, "375cdb206cdd56392faa094cdf816ef9604bd777"
config :gitsome, :git_hub_key, "PUT YOUR GITHUB TOKEN HERE"

# Configures the endpoint
config :gitsome, GitsomeWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1tnMuzkRqgTIxPO5WaTAj6NpXrwLk47g5ASsdRPDqOMl/WTwmotHuhsgs/7XOSkt",
  render_errors: [view: GitsomeWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Gitsome.PubSub,
  live_view: [signing_salt: "ib83CB3Z"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
