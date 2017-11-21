defmodule BrodEx.Client do
  @moduledoc false

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      otp_app = Keyword.fetch!(opts, :otp_app)

      @otp_app otp_app

      @default_brod_client :default_brod_client

      alias BrodEx.Config
      alias Brodex.KafkaMessage

      @type endpoint :: String.t
      @type endpoints :: [endpoint] | String.t

      def start_link(opts \\ []) do
        config  = Application.get_env(@otp_app, __MODULE__, [])
        Config.build_config(config)
        :brod.start(:normal, nil)
      end

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end
    end
  end
end
