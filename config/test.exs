import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cowRoll, CowRollWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "HRK89wNvLfRqBcOtwmzqqjWYnTWgjm1THLJIhVvsM11q7KR5ZgCzVYtp+Qr8iaNG",
  server: false

# In test we don't send emails.
config :cowRoll, CowRoll.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :cowRoll,
       :jwt_secret_key,
       "NJE0mYkGzN/cDO5ro1jLjCDIPYnKc2+PTwVVZBBTH9zZNqYz9lK7Hw+ByIAnrUKKjb7xftAgvhuwJ2q/ZfwPNg=="

config :cowRoll, CowRoll.Mongo, database: "cowRollTest"
