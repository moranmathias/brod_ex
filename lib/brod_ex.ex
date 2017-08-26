defmodule BrodEx do
  @moduledoc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      otp_app = Keyword.fetch!(opts, :otp_app)
      use BrodEx.Client, otp_app: otp_app
      use BrodEx.Producer
      use BrodEx.Consumer

    end
  end
end
