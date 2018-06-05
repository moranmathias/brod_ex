use Mix.Config

config :sasl, :sasl_error_logger, false

config :example, Example.BrodClient, endpoints: ["localhost:9092"]

