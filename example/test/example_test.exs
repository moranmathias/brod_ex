defmodule ExampleTest do
  use ExUnit.Case
  doctest Example

  alias Example.BrodClient

  test "brod_ex is started with the example application" do
    apps = Application.started_applications
    assert List.keyfind(apps, :example, 0) != nil
    assert List.keyfind(apps, :brod_ex, 0) != nil
  end

  test "produce a message to kafka" do
    assert :ok = BrodClient.produce_sync("test.topic", 0, "key", "value")
  end

end

