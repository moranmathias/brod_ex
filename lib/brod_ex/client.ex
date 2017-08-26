defmodule BrodEx.Client do
  @moduledoc false

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      otp_app = Keyword.fetch!(opts, :otp_app)
      config  = Application.get_env(otp_app, __MODULE__, [])

      @default_brod_client :default_brod_client

      alias BrodEx.Config
      alias Brodex.KafkaMessage

      @type endpoint :: String.t
      @type endpoints :: [endpoint] | String.t
      
      def start_link(opts \\ []) do
        Config.build_config(unquote(config))
        :brod.start(:normal, nil)
      end
      
    end
  end
end
