defmodule BrodEx.Client do
  @moduledoc false

  defmacro __using__(module_opts \\ []) do
    quote bind_quoted: [module_opts: module_opts] do
      @otp_app Keyword.fetch!(module_opts, :otp_app)

      alias BrodEx.Config

      def start_link(opts \\ []) do
        client_config = Application.get_env(@otp_app, __MODULE__, [])
                        |> Keyword.merge(opts)
                        |> Config.brod_client_config()
        clients = Application.get_env(:brod, :clients, [])
                  |> Keyword.merge([{__MODULE__, client_config}])

        Application.put_env(:brod, :clients, clients)

        :brod.start_link_client(client_config[:endpoints], __MODULE__, client_config)
      end

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :worker
        }
      end

      def produce_sync(topic, partition, key, value) do
        BrodEx.produce_sync(__MODULE__, topic, partition, key, value)
      end

    end
  end

end
