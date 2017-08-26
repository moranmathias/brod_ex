defmodule BrodEx.Producer do
  @moduledoc false
  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do

      alias BrodEx.Records

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
      @spec produce(pid, :brod.value) :: {:ok, Records.brod_call_ref} | {:error, any}
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
    end
  end
end
