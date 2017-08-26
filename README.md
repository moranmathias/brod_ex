# BrodEx - Brod Wrapper for Elixir

*WARNING: Work in progress*

Brod is an erlang implementation of the Apache Kafka protocol, providing support for both producers and consumers.

Why "brod"? [http://en.wikipedia.org/wiki/Max_Brod](http://en.wikipedia.org/wiki/Max_Brod)

# Features

* Supports Apache Kafka v0.8+
* Robust producer implementation supporting in-flight requests and asynchronous acknowledgements
* Both consumer and producer handle leader re-election and other cluster disturbances internally
* Opens max 1 tcp connection to a broker per "brod_client", one can create more clients if needed
* Producer: will start to batch automatically when number of unacknowledged (in flight) requests exceeds configurable maximum
* Producer: will try to re-send buffered messages on common errors like "Not a leader for partition", errors are resolved automatically by refreshing metadata
* Simple consumer: The poller, has a configurable "prefetch count" - it will continue sending fetch requests as long as total number of unprocessed messages (not message-sets) is less than "prefetch count"
* Group subscriber: Support for consumer groups with options to have Kafka as offset storage or a custom one
* Topic subscriber: Subscribe on messages from all or selected topic partitions without using consumer groups

# Missing features

* lz4 compression & decompression
* new 0.10 on-wire message format
* new 0.10.1.0 create/delete topic api

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `brod_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:brod_ex, git: "git://github.com/moranmathias/brod_ex.git"}]
end
```

## Usage

Create a Brod module in your app like this:

```elixir
defmodule MyApp.Brod do
  use BrodEx, otp_app: :your_app
end
```

Finally start it in your application

```elixir
def start(_type, _args) do
  import Supervisor.Spec

  children = [
    supervisor(MyApp.Brod, [])
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

# Overview

Brod supervision (and process link) tree.

![](https://cloud.githubusercontent.com/assets/164324/19621338/0b53ccbe-9890-11e6-9142-432a3a87bcc7.jpg)

# Clients

A `brod_client` in brod is a `gen_server` responsible for establishing and 
maintaining tcp sockets connecting to kafka brokers. 
It also manages per-topic-partition producer and consumer processes under 
two-level supervision trees.

## Start clients by default

You may include client configs in config.exs have them started by default 
(by application controller)

Example of configuration (for config.exs):

```elixir
config :your_app, BrodExTest.Brod,
  clients: [brod_client_1: [endpoints: ["localhost:9092"],
                            reconnect_cool_down_seconds: 10]] 
```

## Start brod client on demand

You may also call `BrodEx.start_client/1,2,3` to start a client on demand, 
which will be added to brod supervision tree.

```elixir
:ok = MyApp.Brod.start_client(["localhost:9092"], :brod_client_1, reconnect_cool_down_seconds: 10)
```

# Producers

## Auto start producer with default producer config

Put below configs to client config in config.exs:

```elixir
auto_start_producers: true,
default_producer_config: []
```

## Start a producer on demand

```elixir
:ok = MyApp.Brod.start_producer(:brod_client_1, "test", [])
```

## Produce to a known topic-partition:

```elixir
{ok, call_ref} = MyApp.Brod.produce(brod_client_1,
                                      "brod-test-topic-1",
                                      0,
                                      "some-key",
                                      "some-value")
# just to illustrate what message to expect
receive
  {:brod_produce_reply, call_ref, :brod_produce_req_acked} -> ok
after 5000 ->
  :erlang.exit(timeout)
end.
```

## Synchronized produce request

Block calling process until Kafka confirmed the message:

```elixir
{ok, call_ref} = MyApp.Brod.produce(:brod_client_1,
                                     "brod-test-topic-1",
                                     0,
                                     "some-key",
                                     "some-value")
MyApp.Brod.sync_produce_request(call_ref)
```

or the same in one call:

```elixir
MyApp.Brod.produce_sync(brod_client_1,
                  "brod-test-topic-1",
                  0,
                  "some-key",
                  "some-value").
```

## Produce with random partitioner

```elixir
client = :brod_client_1,
topic  = "brod-test-topic-1",
partition_fun = fn (topic, partitions_count, _key, _value) ->
                   {:ok, :crypto.rand_uniform(0, partitions_count)}
               end
{:ok, call_ref} = MyApp.Brod.produce(client, topic, &partition_fun/4, key, value)
```

## Produce a batch of (maybe nested) Key-Value list

```elixir
# The top-level key is used for partitioning
# and nested keys are discarded.
# Nested messages are serialized into a message set to the same partition.
MyApp.Brod.produce(brod_client_1,
                     "brod-test-topic-1",
                     &my_partitioner_fun/4,
                     key_used_for_partitioning,
                     [ {"k1", "v1"},
                       {"k2", "v2"},
                       {[{"k3", "v3"}, {"k4", "v4"}]}
                     ])
```

## Handle acks from kafka

Unless MyApp.Brod.produce_sync was called, callers of MyApp.Brod.produce should 
expect a message of below pattern for each produce call. 
Add BrodEx.BrodProduceReply to use the record.

```elixir
{
  :brod_produce_reply,
  call_ref, # returned from MyApp.Brod.produce
  :brod_produce_req_acked
}
```

NOTE: If required_acks is set to 0 in producer config, 
kafka will NOT ack the requests, and the reply message is sent back 
to caller immediately after the message has been sent to the socket process.

In case the MyApp.Brod.produce caller is a process like gen_server which 
receives ALL messages, the callers should keep the call references in its 
looping state and match the replies against them when received. 
Otherwise MyApp.Brod.sync_produce_request/1 can be used to block-wait for acks.

NOTE: The replies are only strictly ordered per-partition. 
i.e. if the caller is producing to two or more partitions, 
it may receive replies ordered differently than in which order 
MyApp.Brod.produce API was called.

# Consumers

Kafka consumers work in poll mode. In brod, `brod_consumer` is the poller, 
which is constantly asking for more data from the kafka node which is a leader 
for the given partition.

By subscribing to `brod_consumer` a process should receive the polled message 
sets (not individual messages) into its mailbox.

In brod, we have so far implemented two different subscribers 
(`brod_topic_subscriber` and `brod_group_subscriber`), 
hopefully covered most of the common use cases.

For maximum flexibility, an applications may implement their own 
per-partition subscriber.

Below diagrams illustrate 3 examples of how subscriber processes may work 
with `brod_consumer`.

## Partition subscriber
![](https://cloud.githubusercontent.com/assets/164324/19621677/5e469350-9897-11e6-8c8e-8a6a4f723f73.jpg)

This gives the best flexibility as the per-partition subscribers work 
directly with per-partition pollers.

The messages are delivered to subscribers in message sets (batches), 
not individual messages, (however the subscribers are allowed to 
ack individual offsets).

## Topic subscriber (`brod_topic_subscriber`)
![](https://cloud.githubusercontent.com/assets/164324/19621951/41e1d75e-989e-11e6-9bc2-49fe814d3020.jpg)

A topic subscriber provides the easiest way to receive and process 
messages from ALL partitions of a given topic.  See `brod_demo_cg_collector` 
and `brod_demo_topic_subscriber` for example.

Users may choose to implement the `brod_topic_subscriber` behaviour callbacks 
in a module, or simply provide an anonymous callback function to have the 
individual messages processed.

## Group subscriber (`brod_group_subscriber`)
![](https://cloud.githubusercontent.com/assets/164324/19621956/59d76a9a-989e-11e6-9633-a0bc677e06f3.jpg)

Similar to topic subscriber, the `brod_group_subscriber` behaviour callbacks 
are to be implemented to process individual messages. See 
`brod_demo_group_subscriber_koc` and `brod_demo_group_subscriber_loc` 
for example.

A group subscriber is started by giving a set of topics, some 
(maybe none, or maybe all) of the partitions in the topic set will be 
assigned to it, then the subscriber should subscribe to ALL the assigned 
partitions.

Users may also choose to implement the `brod_group_member` behaviour (callbacks 
for `brod_group_coordinator`) for a different group subscriber (e.g. spawn 
one subscriber per partition), see [brucke](https://github.com/klarna/brucke) 
for example.

### Example of group consumer which commits offsets to Kafka

```elixir
defmodule MyApp.YourSubscriber do
  require Logger
  alias BrodEx.KafkaMessage
  
  def init(_group_id, _args), do: {:ok, []}

  def handle_message(topic, partition, message, state) do
    {KafkaMessage, offset, key, value} = message
    Logger.error("#{self} #{partition}: offset: #{offset} key:#{key}, value:#{value}")
    {:ok, :ack, state}
  end

  @doc """
    The brod client identified ClientId should have been started
    either by configured in sys.config and started as a part of brod application
    or started by MyApp.Brod.start_client/3
  """
  @spec start(:brod.client_id()) :: {:ok, pid}
  def start(client_id) do
    topic  = "brod-test-topic-1"
    # commit offsets to kafka every 5 seconds
    group_config = [{offset_commit_policy, commit_to_kafka_v2},
                  {offset_commit_interval_seconds, 5}]
    group_id = "my-unique-group-id-shared-by-all-members"
    consumer_config = [{:begin_offset, :earliest}]
    MyApp.Brod.start_link_group_subscriber(client_id, group_id, [topic],
                                    group_config, consumer_config,
                                    __MODULE__, [])
  end
end
```

# Other API to play with/inspect kafka

These functions open a connetion to kafka cluster, send a request,
await response and then close the connection.

```elixir
hosts = ["localhost:9092"]
topic = "topic"
partition = 0
MyApp.Brod.get_metadata(hosts).
MyApp.Brod.get_metadata(hosts, [topic])
MyApp.Brod.get_offsets(hosts, topic, partition)
MyApp.Brod.fetch(hosts, topic, partition, 1)
```



Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/brod_ex](https://hexdocs.pm/brod_ex).

