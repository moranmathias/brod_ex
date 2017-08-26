defmodule BrodEx.Config do
  @moduledoc false

  @type endpoint :: {charlist, pos_integer} | {}
  @type endpoints :: [endpoint]

  @type client_option :: {:endpoints, endpoints | String.t} |
                         {:reconnect_cool_down_seconds, integer} |
                         {:auto_start_producers, boolean} |
                         {:default_producer_config, :brod.producer_config}
  @type config_option :: {:client, [client_option]}

  @spec build_config([config_option]) :: :ok
  def build_config(config) do
    raw_clients = Keyword.get(config, :clients, [])
    clients = parse_clients(raw_clients)
    Application.put_env(:brod, :clients, clients)
  end

  @spec parse_endpoints([String.t] | String.t) :: endpoints
  def parse_endpoints(endpoints) when is_bitstring(endpoints) do
    endpoints
    |> String.split([";"," "], trim: true)
    |> parse_endpoints  
  end

  def parse_endpoints(endpoints) do
    endpoints
    |> Enum.map(&parse_endpoint/1)
    |> Enum.filter(fn {_, _} -> true
                      _ -> false 
                   end)
  end

  @spec parse_endpoint(String.t) :: endpoint
  def parse_endpoint(endpoint) do
    endpoint
    |> String.split(":")
    |> (fn [h , p] -> [String.to_charlist(h), String.to_integer(p)]
                    [_] -> []
                end).()
    |> List.to_tuple
  end

  defp parse_clients(clients) do
    parse_clients(clients, [])
  end

  defp parse_clients([{name, config} | tail], acc) do
    endpoints = config |> Keyword.get(:endpoints, [])
    new_config = config
    |> Keyword.put(:endpoints, parse_endpoints(endpoints))
    parse_clients(tail, Keyword.put(acc, name, new_config))
  end

  defp parse_clients([], acc) do
    acc
  end
end
