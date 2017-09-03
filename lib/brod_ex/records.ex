defmodule BrodEx.Records do
  @moduledoc false
  require Record
  import Record, only: [defrecord: 2, extract: 2]

  defrecord :kafka_message, extract(:kafka_message, from_lib: "kafka_protocol/include/kpro_public.hrl")

  @type kafka_message :: record(:kafka_message,
        offset: :kpro.offset,
        magic_byte: :kpro.int8,
        attributes: :kpro.int8,
        key: :kpro.bytes,
        value: :kpro.bytes,
        crc: non_neg_integer,
        ts_type: :kpro.timestamp_type,
        ts: :kpro.int64)

  defrecord :brod_produce_reply, extract(:brod_produce_reply, from_lib: "brod/include/brod.hrl")

  @type brod_produce_reply :: record(:brod_produce_reply,
                    call_ref: brod_call_ref,
                    result: :brod.produce_result())

  defrecord :brod_call_ref, extract(:brod_call_ref, from_lib: "brod/include/brod.hrl")

  @type brod_call_ref :: record(:brod_call_ref,
                    caller: pid,
                    callee: pid,
                    ref: reference)

  defrecord :kafka_message_set, extract(:kafka_message_set, from_lib: "brod/include/brod.hrl")

  @type kafka_message_set :: record(:kafka_message_set,
      topic: :brod.topic(),
      partition: :brod.partition(),
      high_wm_offset: integer(), # max offset of the partition
      messages:  [:brod.message()] | :kpro.incomplete_message())

  defrecord :kafka_fetch_error, extract(:kafka_fetch_error, from_lib: "brod/include/brod.hrl")

  @type kafka_fetch_error :: record(:kafka_fetch_error,
        topic: :brod.topic(),
        partition: :brod.partition(),
        error_code: :brod.error_code(),
        error_desc: binary()
        )
  defrecord :kafka_group_member_metadata,
            extract(:kafka_group_member_metadata, from_lib: "brod/include/brod.hrl")

  @type kafka_group_member_metadata :: record(
        :kafka_group_member_metadata,
        version: non_neg_integer(),
        topics: [:brod.topic()],
        user_data: binary())

  defrecord :brod_received_assignment,
            extract(:brod_received_assignment, from_lib: "brod/include/brod.hrl")

  @type brod_received_assignment :: record(:brod_received_assignment,
          topic: :brod.topic(),
          partition: :brod.partition(),
          begin_offset: :undefined | :brod.offset())
end
