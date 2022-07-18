defmodule PhxPlatformUtils.Rabbit.Client do
  require Logger
  use GenServer
  use AMQP

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @exchange "amq.topic"

  def init(opts) do
    try do
      {:ok, conn} = Connection.open(host: opts[:host], port: opts[:port], username: opts[:user], password: opts[:pass])
      Logger.debug("RabbitMQ: connection opened")
      {:ok, chan} = Channel.open(conn)
      Logger.debug("RabbitMQ: channel opened")
      {:ok} = setup_queues(chan, opts[:subscriptions])
      :ok = Basic.qos(chan, prefetch_count: 10)
      Logger.debug("RabbitMQ: initialization finished, success!")
      {:ok, chan}
    rescue
      exception ->
        Logger.error("RabbitMQ: initialization failed:")
        Logger.error(exception)
        {:error, exception}
    end
  end

  defp setup_queues(chan, consumers) do
    queue_setup_results =
      consumers
      |> Enum.map(&setup_queue(chan, {&1.topic, &1.handler}))
      |> Enum.filter(fn
        {:error, _err} -> true
        _ -> false
      end)

    with [{:error, exception} | _rest] <- queue_setup_results do
      {:error, exception}
    end

    {:ok}
  end

  defp setup_queue(chan, {queue, handler}) do
    try do
      {:ok, _} = Queue.declare(chan, queue, durable: true)
      Logger.debug("RabbitMQ: queue #{queue} declared")
      :ok = Queue.bind(chan, queue, @exchange, routing_key: queue)
      Logger.debug("RabbitMQ: queue #{queue} bound")
      {:ok, _} = subscribe(chan, queue, handler)
      Logger.debug("RabbitMQ: subscription and consumer for #{queue} created")
      {:ok}
    rescue
      exception ->
        {:error, exception}
    end
  end

  def subscribe(%Channel{} = channel, queue, fun, options \\ [always_ack?: true]) when is_function(fun, 2) do
    consumer_pid = spawn(fn -> do_start_consumer(channel, fun, options[:always_ack?]) end)
    Basic.consume(channel, queue, consumer_pid, options)
  end

  defp do_start_consumer(channel, fun, always_ack?) do
    receive do
      {:basic_consume_ok, %{consumer_tag: consumer_tag}} ->
        do_consume(channel, fun, consumer_tag, always_ack?)
    end
  end

  defp do_consume(channel, fun, consumer_tag, always_ack?) do
    receive do
      {:basic_deliver, payload, %{delivery_tag: delivery_tag, redelivered: redelivered?} = meta} ->
        if always_ack? do
          # Always ACK regardless of outcome
          Basic.ack(channel, delivery_tag)
        end

        try do
          decoded = Jason.decode!(payload)
          Logger.info("Messaged received on #{meta.routing_key}")

          unless always_ack? do
            Basic.ack(channel, delivery_tag)
          end

          fun.(decoded, meta)
        rescue
          exception ->
            Logger.error("Error consuming message on delivery_tag '#{delivery_tag}'")
            Logger.error(exception)

            unless always_ack? do
              Basic.reject(channel, delivery_tag, requeue: not redelivered?)
            end
        end

        do_consume(channel, fun, consumer_tag, always_ack?)

      {:basic_cancel, %{consumer_tag: ^consumer_tag}} ->
        exit(:basic_cancel)

      {:basic_cancel_ok, %{consumer_tag: ^consumer_tag}} ->
        exit(:normal)
    end
  end

  defp publish_to_topic(chan, topic, message) do
    payload = Jason.encode!(message)

    case Basic.publish(chan, @exchange, topic, payload) do
      :ok ->
        Logger.info("RabbitMQ: successfully published message to: #{topic}")

      {:error, error} ->
        Logger.error("RabbitMQ: failed to publish message to: #{topic}", error)
    end
  end

  def handle_call({:publish_message, {topic, message}}, _, chan) do
    publish_to_topic(chan, topic, message)
    {:reply, :ok, chan}
  end

  def handle_cast({:publish_message, {topic, message}}, chan) do
    publish_to_topic(chan, topic, message)
    {:noreply, chan}
  end

  def call(request) do
    GenServer.call(__MODULE__, {:publish_message, request})
  end

  def cast(request) do
    GenServer.cast(__MODULE__, {:publish_message, request})
  end
end