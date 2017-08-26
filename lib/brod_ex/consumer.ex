defmodule BrodEx.Consumer do
  @moduledoc false

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
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
  end
end