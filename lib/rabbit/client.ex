defmodule PhxPlatformUtils.Rabbit.Client do
  require Logger
  use GenServer
  use AMQP

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @exchange    "amq.topic"

  def init(opts) do
    with {:ok, conn} <- Connection.open([host: opts[:host], port: opts[:port], username: opts[:user], password: opts[:pass]]) do
      Logger.debug("RabbitMQ: connection opened")
        with {:ok, chan} <- Channel.open(conn) do
          Logger.debug("RabbitMQ: channel opened")
          with {:ok} <- setup_queues(chan, opts[:subscriptions]) do
            # Limit unacknowledged messages to 10
            # not sure about this - from example
            with :ok <- Basic.qos(chan, prefetch_count: 10) do
              Logger.debug("RabbitMQ: start up finished, success!")
              {:ok, chan}
            else
              {:error, error} ->
                Logger.error("failed to limit unacknowledged messages to 10")
                {:stop, :error, error}
            end
          else
            {:error, errors} ->
              Logger.error("failed to set up queues and subscriptions")
              {:stop, :error, errors}
          end
        else
          {:error, error} ->
            Logger.error("failed to open channel")
            {:stop, :error, error}
        end
    else
      {:error, error} ->
        Logger.error("failed to open ampq connection")
        {:stop, :error, error}
    end
  end

  defp setup_queues(chan, subscriptions) do
    subscriptions
      |> Enum.map(fn sub -> setup_queue(chan, {sub.topic, sub.handler}) end)
      |> Enum.split_with(fn {:error, _} -> true; _ -> false end)
      |> case do
        {[], _} ->
          {:ok}
        {errors, _} ->
           {:error, errors}
        end
  end

  defp setup_queue(chan, {topic, handler}) do
    with {:ok, _} <- Queue.declare(chan, topic, durable: true) do
      Logger.debug("RabbitMQ: queue #{topic} declared")
      with :ok <- Queue.bind(chan, topic, @exchange, [routing_key: topic]) do
        Logger.debug("RabbitMQ: queue #{topic} bound")
        with {:ok, _} <- subscribe(chan, topic, handler) do
          Logger.debug("RabbitMQ: subscription and consumer for #{topic} created")
          {:ok}
        else
          error ->
            Logger.error("Error subscribing to queue for topic: #{topic}", error)
            {:error, error}
        end
      else
        error ->
          Logger.error("Error binding to queue for topic: #{topic}", error)
          {:error, error}
      end
    else
      error ->
        Logger.error("Error creating queue for topic: #{topic}", error)
        {:error, error}
    end
  end

  def subscribe(%Channel{} = channel, queue, fun, options \\ []) when is_function(fun, 2) do
    consumer_pid = spawn(fn -> do_start_consumer(channel, fun) end)
    Basic.consume(channel, queue, consumer_pid, options)
  end

  defp do_start_consumer(channel, fun) do
    receive do
      {:basic_consume_ok, %{consumer_tag: consumer_tag}} ->
        do_consume(channel, fun, consumer_tag)
    end
  end

  defp do_consume(channel, fun, consumer_tag) do
    receive do
      {:basic_deliver, payload, %{delivery_tag: delivery_tag} = meta} ->
        try do
          decoded = Jason.decode!(payload)
          Logger.info("Messaged received on #{meta.routing_key}")
          fun.(decoded, meta)
          Basic.ack(channel, delivery_tag)
        rescue
          exception ->
            Basic.reject(channel, delivery_tag, requeue: false)
            reraise exception, __STACKTRACE__
        end

        do_consume(channel, fun, consumer_tag)

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
