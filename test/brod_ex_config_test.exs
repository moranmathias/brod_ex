defmodule Brodex.ConfigTest do
  @moduledoc false
  use ExUnit.Case

  alias BrodEx.Config

  @test_endpoint "localhost:9092"
  @parsed_endpoint {'localhost', 9092}
  @test_endpoints [@test_endpoint, @test_endpoint]
  @parsed_endpoints [@parsed_endpoint, @parsed_endpoint]

  test "parse_endpoint" do
    assert Config.parse_endpoint(@test_endpoint) == @parsed_endpoint
    assert Config.parse_endpoint("") == {}
  end

  test "parse_endpoints" do
    assert Config.parse_endpoints(@test_endpoints) == @parsed_endpoints
    assert Config.parse_endpoints([@test_endpoint, "error_host"]) == [@parsed_endpoint]
    assert Config.parse_endpoints(["error_host"]) == []

    assert Config.parse_endpoints(~s(#{@test_endpoint}; #{@test_endpoint})) == @parsed_endpoints
    assert Config.parse_endpoints(~s(#{@test_endpoint};#{@test_endpoint})) == @parsed_endpoints
    assert Config.parse_endpoints(~s(#{@test_endpoint}; error_host)) == [@parsed_endpoint]
    assert Config.parse_endpoints("error_host") == []

  end

  test "build_config" do
    assert Config.build_config(clients: [test_client: [endpoints: "localhost:9092"]]) == :ok
    assert Application.get_env(:brod,
      :clients) == [test_client: [endpoints: [@parsed_endpoint]]]

    assert Config.build_config(clients: [test_client: [endpoints: "localhost:9092; localhost:9092"]]) == :ok
    assert Application.get_env(:brod,
      :clients) == [test_client: [endpoints: @parsed_endpoints]]

    assert Config.build_config(
        clients: [test_client: [endpoints: ["localhost:9092", "localhost:9092"]]]) == :ok
    assert Application.get_env(:brod,
        :clients) == [test_client: [endpoints: @parsed_endpoints]]

    assert Config.build_config(clients: [test_client: [endpoints: "localhost:9092 localhost:9092"]]) == :ok
    assert Application.get_env(:brod,
      :clients) == [test_client: [endpoints: @parsed_endpoints]]
  end
end
