use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :pan, PanWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
             cd: Path.expand("../assets", __DIR__)]]

# Watch static and templates for browser reloading.
config :pan, PanWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/pan_web/views/.*(ex)$},
      ~r{lib/pan_web/templates/.*(eex)$}
    ]
  ]

# Mailer config
config :pan, Pan.Mailer,
  adapter: Bamboo.LocalAdapter

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development.
# Do not configure such in production as keeping
# and calculating stacktraces is usually expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :pan, Pan.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "pan_dev",
  hostname: "localhost",
  pool_size: 10,
  timeout: 1_000_000

config :pan, :environment, "dev"
import_config "dev.secret.exs"

# Uncomment the next two lines to send emails from dev as well

# config :logger, backends:
#   [:console, {Logger.Backends.ExceptionNotification, :exeception_notification}]
