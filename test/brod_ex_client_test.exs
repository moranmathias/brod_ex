defmodule Brodex.ClientTest do
  @moduledoc false
  use ExUnit.Case

  Application.put_env(:test_app, :clients, [])
  defmodule TestApp.Brod do
    @moduledoc false
    use BrodEx, otp_app: :test_app
  end

  setup do
    :ok = TestApp.Brod.start_link([])

    on_exit fn ->
      BrodEx.stop
    end
  end

  test "start_link" do
    assert Application.started_applications |> List.keyfind(:brod, 0) != nil
  end

  
end
