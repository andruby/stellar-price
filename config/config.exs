# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :pricey,
  ecto_repos: [Pricey.Repo]

# Configures the endpoint
config :pricey, PriceyWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "I21/o73oanU/9FBW8TBfKNck7yYwI9X4QemTzFcLAN8a4WM34AEdo/Bqn1MhfH+e",
  render_errors: [view: PriceyWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Pricey.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
