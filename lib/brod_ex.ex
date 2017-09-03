defmodule BrodEx do
  @moduledoc false

  alias BrodEx.Records
  alias BrodEx.Config

  @type endpoint :: String.t
  @type endpoints :: [endpoint] | String.t

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      otp_app = Keyword.fetch!(opts, :otp_app)
      use BrodEx.Client, otp_app: otp_app
    end
  end

  @doc "Start BrodEx application."
  @spec start() :: :ok | no_return
  def start do
    :brod.start()
  end

  @doc "Application behaviour callback"
  defdelegate start(_start_type, _args), to: :brod

  @doc "Stop brod application."
  @spec stop() :: :ok
  defdelegate stop(), to: :brod

  @doc """
  Start a client.
  BootstrapEndpoints:
    Kafka cluster endpoints, can be any of the brokers in the cluster
    which does not necessarily have to be a leader of any partition,
    e.g. a load-balanced entrypoint to the remote kakfa cluster.
  ClientId:
    Atom to identify the client process
  Config:
    Proplist, possible values:
      restart_delay_seconds (optional, default=10)
        How much time to wait between attempts to restart brod_client
        process when it crashes
      max_metadata_sock_retry (optional, default=1)
        Number of retries if failed fetching metadata due to socket error
      get_metadata_timeout_seconds(optional, default=5)
        Return timeout error from brod_client:get_metadata/2 in case the
        respons is not received from kafka in this configured time.
      reconnect_cool_down_seconds (optional, default=1)
        Delay this configured number of seconds before retrying to
        estabilish a new connection to the kafka partition leader.
      allow_topic_auto_creation (optional, default=true)
        By default, brod respects what is configured in broker about
        topic auto-creation. i.e. whatever auto.create.topics.enable
        is set in borker configuration.
        However if 'allow_topic_auto_creation' is set to 'false' in client
        config, brod will avoid sending metadata requests that may cause an
        auto-creation of the topic regardless of what the broker config is.
      auto_start_producers (optional, default=false)
        If true, brod client will spawn a producer automatically when
        user is trying to call 'produce' but did not call
        brod:start_producer explicitly. Can be useful for applications
        which don't know beforehand which topics they will be working with.
      default_producer_config (optional, default=[])
        Producer configuration to use when auto_start_producers is true.
        @see brod_producer:start_link/4. for details about producer config
      ssl (optional, default=false)
        true | false | [{certfile, ...},{keyfile, ...},{cacertfile, ...}]
        When true, brod will try to upgrade tcp connection to ssl using default
        ssl options. List of ssl options implies ssl=true.
      sasl (optional, default=undefined)
        Credentials for SASL/Plain authentication.
        {plain, "username", "password"}
      connect_timeout (optional, default=5000)
        Timeout when trying to connect to one endpoint.
      request_timeout (optional, default=240000, constraint: >= 1000)
        Timeout when waiting for a response, socket restart when timedout.
  """

  @default_brod_client :default_brod_client

  @spec start_client(String.t) :: :ok | {:error, any}
  def start_client(bootstrap_endpoints) do
    start_client(bootstrap_endpoints, @default_brod_client, [])
  end

  @spec start_client(endpoint, atom) :: :ok | {:error, any}
  def start_client(bootstrap_endpoints, client_id) do
    start_client(bootstrap_endpoints, client_id, [])
  end

  @spec start_client(endpoint | endpoints | [tuple],
                     :brod.client, :brod.client_config) :: :ok | {:error, any}
  def start_client(bootstrap_endpoints, client_id, config)
  def start_client(bootstrap_endpoints, client_id, config) when is_binary(bootstrap_endpoints) do
    endpoints = Config.parse_endpoints(bootstrap_endpoints)
    start_client(endpoints, client_id, config)
  end

  def start_client([endpoint | _] = endpoints, client_id, config) when is_binary(endpoint) do
    start_client(Config.parse_endpoints(endpoints), client_id, config)
  end

  defdelegate start_client(endpoints, client_id, config), to: :brod

  @spec start_link_client(endpoint | endpoints | [tuple],
                          :brod.client, :brod.client_config) :: {:ok, pid} |
                                                                {:error, any}
  def start_link_client(bootstrap_endpoints, client_id, config)
  def start_link_client(bootstrap_endpoints, client_id, config) when is_binary(bootstrap_endpoints) do
    endpoints = Config.parse_endpoints(bootstrap_endpoints)
    start_link_client(endpoints, client_id, config)
  end

  def start_link_client([endpoint | _] = endpoints, client_id, config) when is_binary(endpoint) do
    start_link_client(Config.parse_endpoints(endpoints), client_id, config)
  end

  defdelegate start_link_client(endpoints, client_id, config), to: :brod

  @spec stop_client(:brod.client) :: :ok
  defdelegate stop_client(client), to: :brod

  @doc """
    Fetch broker metadata
    Return the message body of metadata_response.
    See `kpro_schema.erl' for struct details
  """
  @spec get_metadata(endpoints, [:brod.topic]) ::
          {:ok, :kpro.struct} | {:error, any}
  def get_metadata([endpoint | _] = endpoints, topics) when is_binary(endpoint) do
    endpoints
    |> Config.parse_endpoints
    |> :brod.get_metadata(topics)
  end

  @doc """
    Fetch broker metadata
    Return the message body of metadata_response.
    See `kpro_schema.erl' for struct details
  """
  @spec get_metadata(endpoints, [:brod.topic], :brod.sock_opts) ::
          {:ok, :kpro.struct} | {:error, any}
  def get_metadata([endpoint | _] = endpoints, topics, config) when is_binary(endpoint) do
    endpoints
    |> Config.parse_endpoints
    |> :brod.get_metadata(topics, config)
  end

  @doc "equiv resolve_offset(hosts, topic, partition, :latest, 1)"
  @spec resolve_offset(endpoints, :brod.topic, :brod.partition) ::
          {:ok, [:brod.offset]} | {:error, any}
  def resolve_offset(endpoints, topic, partition) do
    resolve_offset(endpoints, topic, partition, :latest, [])
  end

  @doc """
    Resolve semantic offset or timestamp to real offset.
  """
  @spec resolve_offset(endpoints, :brod.topic,
                        :brod.partition, :brod.offset_time) ::
                        {:ok, [:brod.offset]} | {:error, any}
  def resolve_offset(endpoints, topic, partition, time) do
    resolve_offset(endpoints, topic, partition, time, [])
  end

  @doc """
    Resolve semantic offset or timestamp to real offset.
  """
  @spec resolve_offset(endpoints, :brod.topic, :brod.partition,
                        :brod.offset_time, :brod.sock_opts) ::
                        {:ok, [:brod.offset]} | {:error, any}
  def resolve_offset([endpoint | _] = endpoints, topic,
                      partition, time, options)
                      when is_binary(endpoint) do
    endpoints
    |> Config.parse_endpoints
    |> :brod.resolve_offset(topic, partition, time, options)
  end

  @doc "equiv fetch(hosts, topic, partition, offset, 1000, 0, 100000)"
  @spec fetch(endpoints, :brod.topic, :brod.partition, integer) ::
                {:ok, [Records.kafka_message]} | {:error, any}
  def fetch(hosts, topic, partition, offset) do
    fetch(hosts, topic, partition, offset, 1000, 0, 100_000, [])
  end

  @doc "equiv fetch(hosts, topic, partition, offset, wait, min_bytes, max_bytes, [])"
  @spec fetch(endpoints, :brod.topic, :brod.partition, :brod.offset,
              non_neg_integer, non_neg_integer, pos_integer) ::
                {:ok, [Records.kafka_message]} | {:error, any}
  # credo:disable-for-next-line
  def fetch(endpoints, topic, partition,
            offset, max_wait_time, min_bytes, max_bytes) do
    fetch(endpoints, topic, partition,
          offset, max_wait_time, min_bytes, max_bytes, [])
  end

  @doc """
    Fetch a single message set from the given topic-partition.
  """
  @spec fetch(endpoints, :brod.topic, :brod.partition, :brod.offset,
              non_neg_integer, non_neg_integer, pos_integer,
              :brod.sock_opts) ::
              {:ok, [Records.kafka_message]} | {:error, any}
  def fetch([endpoint | _] = endpoints, topic, partition, offset,
            max_wait_time, min_bytes, max_bytes, options)
            when is_binary(endpoint) do
    endpoints
    |> Config.parse_endpoints
    |> :brod.fetch(topic, partition, offset, max_wait_time, min_bytes,
              max_bytes, options)
  end

  @doc "Connect partition leader."
  @spec connect_leader(endpoints, :brod.topic, :brod.partition,
                      :brod.sock_opts) :: {:ok, pid}
  def connect_leader([endpoint | _] = endpoints, topic, partition, options)
                    when is_binary(endpoint) do
    endpoints
    |> Config.parse_endpoints
    |> :brod.connect_leader(topic, partition, options)
  end

  defdelegate connect_leader(hosts, topic, partition, options), to: :brod

  @doc """
    List ALL consumer groups in the given kafka cluster.
    NOTE: Exception if failed against any of the coordinator brokers.
  """
  @spec list_all_groups(endpoints, :brod.sock_opts) ::
          [{String.t, [:brod.cg] | {:error, any}}]
  def list_all_groups([endpoint | _] = endpoints, options)
                      when is_binary(endpoint) do
      endpoints
      |> Config.parse_endpoints
      |> :brod.list_all_groups(options)
      |> Enum.map(fn {{host, port}, cg} -> {"#{host}:#{port}", cg} end)
  end

  @doc """
    List consumer groups in the given group coordinator broker.
  """
  @spec list_groups(endpoint, :brod.sock_opts) ::
                    {:ok, [:brod.cg]} | {:error, any}
  def list_groups(endpoint, options) when is_binary(endpoint) do
    endpoint
    |> Config.parse_endpoint
    |> :brod.list_groups(options)
  end

  @doc """
    Describe consumer groups. The given consumer group IDs should be all
    managed by the coordinator-broker running at the given endpoint.
    Otherwise error codes will be returned in the result structs.
    Return `describe_groups_response' response body field named `groups'.
    See `kpro_schema.erl' for struct details
  """
  @spec describe_groups(endpoint, :brod.sock_opts, [:brod.group_id]) ::
          {:ok, [:kpro.struct]} | {:error, any}
  def describe_groups(coordinator_endpoint, options, ids)
                      when is_binary(coordinator_endpoint) do
    coordinator_endpoint
    |> Config.parse_endpoint
    |> :brod.describe_groups(options, ids)
  end

  @doc """
    Connect to consumer group coordinator broker.
    Done in steps: 1) connect to any of the given bootstrap ednpoints;
    2) send group_coordinator_request to resolve group coordinator endpoint;;
    3) connect to the resolved endpoint and return the brod_sock pid
  """
  @spec connect_group_coordinator(endpoints,
                                  :brod.sock_opts,
                                  :brod.group_id) ::
                                  {:ok, pid} | {:error, any}
  def connect_group_coordinator([endpoint | _] = endpoints, options, group_id)
                                when is_binary(endpoint) do
    endpoints
    |> Config.parse_endpoints
    |> connect_group_coordinator(options, group_id)
  end

  defdelegate connect_group_coordinator(bootstrap_endpoints,
                                        sock_opts, group_id), to: :brod

  @doc """
    Fetch committed offsets for ALL topics in the given consumer group.
    Return the `responses' field of the `offset_fetch_response' response.
    See `kpro_schema.erl' for struct details.
  """
  @spec fetch_committed_offsets(endpoints,
                                :brod.sock_opts,
                                :brod.group_id) ::
                                {:ok, [:kpro.struct]} | {:error, any}
  def fetch_committed_offsets([endpoint | _] = endpoints, sock_opts, group_id)
                              when is_binary(endpoint) do
    endpoints
    |> Config.parse_endpoints
    |> :brod.fetch_committed_offsets(sock_opts, group_id)
  end

  @doc """
  Same as `fetch_committed_offsets/3', only work on the socket
  connected to the group coordinator broker.
  """
  @spec fetch_committed_offsets(pid, :brod.group_id) ::
          {:ok, [:kpro.struct]} | {:error, any}
  defdelegate fetch_committed_offsets(sock_pid, group_id), to: :brod

  defdelegate get_partitions_count(client, topic), to: :brod

  @doc """
  Dynamically start a per-topic producer.
  @see brod_producer:start_link/4. for details about producer config.
  """
  @spec start_producer(:brod.client,
                        :brod.topic,
                        :brod.producer_config) :: :ok | {:error, any}
  defdelegate start_producer(client, topic_name, producer_config), to: :brod

  @spec get_producer(:brod.client, :brod.topic, :brod.partition) ::
            {:ok, pid} | {:error, reason}
            when reason: :client_down
                      | {:producer_down, :noproc}
                      | {:producer_not_found, :brod.topic}
                      | {:producer_not_found, :brod.topic, :brod.partition}
  defdelegate get_producer(client, topic, partition), to: :brod

  @doc "equiv produce(pid, 0, <<>>, value)"
  @spec produce(pid, :brod.value) :: {:ok, Records.brod_call_ref} |
                                     {:error, any}
  defdelegate produce(pid, value), to: :brod

  @doc """ 
    Produce one message if Value is binary or iolist,
    or a message set if Value is a (nested) kv-list, in this case Key
    is discarded (only the keys in kv-list are sent to kafka).
    The pid should be a partition producer pid, NOT client pid.
  """
  @spec produce(pid, :brod.key, :brod.value) ::
          {:ok, Records.brod_call_ref} | {:error, any}
  defdelegate produce(producer_pid, key, value), to: :brod

  @doc """
    Produce one message if Value is binary or iolist,
    or a message set if Value is a (nested) kv-list, in this case Key
    is used only for partitioning (or discarded if Partition is used
    instead of PartFun).
    This function first lookup the producer pid,
    then call produce/3 to do the real work.
  """
  @spec produce(:brod.client,
                :brod.topic,
                :brod.partition | :brod.partition_fun,
                :brod.key,
                :brod.value) :: {:ok, Records.brod_call_ref} | {:error, any}
  defdelegate produce(client, topic, part_fun, key, value), to: :brod

  @doc "equiv produce_sync(Pid, 0, <<>>, value)"
  @spec produce_sync(pid, :brod.value) :: :ok
  defdelegate produce_sync(pid, value), to: :brod

  @doc """
    Sync version of produce/3
    This function will not return until a response is received from kafka,
    however if producer is started with required_acks set to 0, this function
    will return onece the messages is buffered in the producer process.
  """
  @spec produce_sync(pid, :brod.key, :brod.value) :: :ok | {:error, any}
  defdelegate produce_sync(pid, key, value), to: :brod

  @doc """
    Sync version of produce/5
    This function will not return until a response is received from kafka,
    however if producer is started with required_acks set to 0, this function
    will return once the messages are buffered in the producer process.
  """
  @spec produce_sync(:brod.client,
                      :brod.topic,
                      :brod.partition | :brod.partition_fun,
                      :brod.key, :brod.value) :: :ok | {:error, any}
  defdelegate produce_sync(client, topic, partition, key, value), to: :brod

  @doc """
    Block wait for sent produced request to be acked by kafka.
  """
  @spec sync_produce_request(Records.brod_call_ref) ::
                                          :ok | {:error, reason :: any}
  defdelegate sync_produce_request(call_ref), to: :brod

  @spec sync_produce_request(Records.brod_call_ref, :infinity | :timeout) ::
                                          :ok | {:error, reason :: any}
  defdelegate sync_produce_request(call_ref, timeout), to: :brod

  @doc """ 
    Dynamically start a topic consumer.
    @see brod_consumer:start_link/5. for details about consumer config.
    @end
  """
  @spec start_consumer(:brod.client, :brod.topic, :brod.consumer_config) ::
                                                      :ok | {:error, any}
  defdelegate start_consumer(client, topic_name, consumer_config), to: :brod

  @spec get_consumer(:brod.client, :brod.topic, :brod.partition) ::
            {:ok, pid} | {:error, reason}
            when reason: :client_down
                      | {:consumer_down, :noproc}
                      | {:consumer_not_found, :brod.topic}
                      | {:consumer_not_found, :brod.topic, :brod.partition}
  defdelegate get_consumer(client, topic, partition), to: :brod

  @doc """
    Subscribe data stream from the given topic-partition.
    If {error, Reason} is returned, the caller should perhaps retry later.
    {ok, ConsumerPid} is returned if success, the caller may want to monitor
    the consumer pid to trigger a re-subscribe in case it crashes.
          If subscribed successfully, the subscriber process should expect messages
    of pattern:
    {ConsumerPid, #kafka_message_set{}} and
    {ConsumerPid, #kafka_fetch_error{}},
    -include_lib(brod/include/brod.hrl) to access the records.
    In case #kafka_fetch_error{} is received the subscriber should re-subscribe
    itself to resume the data stream.
  """
  @spec subscribe(:brod.client, pid, :brod.topic, :brod.partition,
                  :brod.consumer_options) :: {:ok, pid} | {:error, any}
  defdelegate subscribe(client, subscriber_pid,
                        topic, partition, options), to: :brod

  @spec subscribe(pid, pid, :brod.consumer_options) :: :ok | {:error, any}
  defdelegate subscribe(consumer_pid, subscriber_pid, options), to: :brod

  @doc "Unsubscribe the current subscriber. Assuming the subscriber is self."
  @spec unsubscribe(:brod.client, :brod.topic,
                    :brod.partition) :: :ok | {:error, any}
  defdelegate unsubscribe(client, topic, partition), to: :brod

  @doc "Unsubscribe the current subscriber."
  @spec unsubscribe(:brod.client, :brod.topic,
                    :brod.partition, pid) :: :ok | {:error, any}
  defdelegate unsubscribe(client, topic,
                          partition, subscriber_pid), to: :brod

  @doc "Unsubscribe the current subscriber. Assuming the subscriber is self."
  @spec unsubscribe(pid) :: :ok | {:error, any}
  defdelegate unsubscribe(consumer_pid), to: :brod

  @doc "Unsubscribe the current subscriber."
  @spec unsubscribe(pid, pid) :: :ok | {:error, any}
  defdelegate unsubscribe(consumer_pid, subscriber_pid), to: :brod

  @spec consume_ack(:brod.client, :brod.topic,
                    :brod.partition, :brod.offset) :: :ok | {:error, any}
  defdelegate consume_ack(client, topic, partition, offset), to: :brod

  @spec consume_ack(pid, :brod.offset) :: :ok | {:error, any}
  defdelegate consume_ack(consumer_pid, offset), to: :brod

  @doc "equiv brod_group_subscriber:start_link/7"
  @spec start_link_group_subscriber(
          :brod.client, :brod.group_id, [:brod.topic],
          :brod.group_config, :brod.consumer_config, module, term) ::
            {:ok, pid} | {:error, any}
  defdelegate start_link_group_subscriber(client, group_id,
                                          topics, group_config,
                                          consumer_config, cb_module,
                                          cb_init_arg), to: :brod

  @doc """
    @equiv start_link_topic_subscriber(client, topic, 
                                      'all', consumer_config,
                                        cb_module, cb_init_arg)
  """
  @spec start_link_topic_subscriber(:brod.client, :brod.topic,
                                    :brod.consumer_config, module, term) ::
                                    {:ok, pid} | {:error, any}
  defdelegate start_link_topic_subscriber(client, topic, consumer_config,
                              cb_module, cb_init_arg), to: :brod

  @doc "@equiv brod_topic_subscriber:start_link/6"
  @spec start_link_topic_subscriber(
          :brod.client, :brod.topic, :all | [:brod.partition],
          :brod.consumer_config, module, term) ::
            {:ok, pid} | {:error, any}
  defdelegate start_link_topic_subscriber(client, topic, partitions,
                              consumer_config, cb_module,
                              cb_init_arg), to: :brod
end
