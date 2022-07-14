defmodule PhxPlatformUtils.Mqtt.Client do
  require Logger
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    result =
      :emqtt.start_link(
        clean_start: false,
        clientid: opts[:client_id],
        host: String.to_atom(opts[:host]),
        name: :emqtt,
        port: opts[:port]
      )

    case result do
      {:ok, pid} ->
        state = %{
          pid: pid,
          topics: Enum.map(opts[:subscriptions], & &1.topic),
          handlers:
            Enum.reduce(opts[:subscriptions], %{}, fn opt, acc ->
              Map.put(acc, "#{opt.topic}", opt.handler)
            end)
        }

        {:ok, state, {:continue, :start_emqtt}}

      {:error, reason} ->
        Logger.error("EMQTT: error in init: #{reason}")
        {:stop, {:error, reason}}
    end
  end

  def handle_continue(:start_emqtt, st) do
    case :emqtt.connect(st.pid) do
      {:ok, _props} ->
        Enum.each(st.topics, fn topic ->
          case :emqtt.subscribe(st.pid, {topic, 1}) do
            {:ok, _props, _reason_codes} ->
              Logger.info("EMQTT: successfully subscribed to #{topic}")

            {:error, reason} ->
              Logger.error("EMQTT: error subscribing to topic: #{topic} reason: #{reason}")
          end
        end)

      {:error, reason} ->
        Logger.error("EMQTT: error in connect: #{reason}")
        {:stop, {:error, reason}, st}
    end

    {:noreply, st}
  end

  def handle_info({:publish, %{topic: topic, payload: payload}}, st) do
    handle_publish(topic, payload, st)
  end

  defp determine_matching_subscriptions(topic, subscription_topics) do
    split_topic =
      topic
      |> String.split("/")

    subscription_topics
    |> Enum.filter(fn subscription_topic ->
      split_subscription_topic =
        subscription_topic
        |> String.split("/")

      match_subscription_recursively(split_topic, split_subscription_topic)
    end)
  end

  defp match_subscription_recursively([_ | _], []), do: false

  defp match_subscription_recursively([], [_ | _]), do: false

  defp match_subscription_recursively([], []), do: true

  defp match_subscription_recursively([message_part | message_topic_parts], [subscription_part | subscription_topic_parts]) do
    case subscription_part do
      "+" ->
        true && match_subscription_recursively(message_topic_parts, subscription_topic_parts)

      "#" ->
        true && length(subscription_topic_parts) == 0

      ^message_part ->
        true && match_subscription_recursively(message_topic_parts, subscription_topic_parts)

      _ ->
        false
    end
  end

  defp handle_publish(topic, payload, st) do
    determine_matching_subscriptions(topic, st.topics)
    |> Enum.each(fn matching_subscription ->
      decoded_payload = Jason.decode!(payload)
      {module, function, args} = st.handlers[matching_subscription]

      case apply(module, function, [topic, decoded_payload | args]) do
        {:ok} ->
          Logger.info("EMQTT: handler for #{topic} successfully executed")

        {:error, reason} ->
          Logger.error("EMQTT: handler for #{topic} failed: #{reason}")

        any ->
          Logger.debug("EMQTT: unknown return from handler for topic: #{topic}", any)
      end
    end)

    {:noreply, st}
  end

  defp publish_to_topic(pid, topic, message) do
    payload = Jason.encode!(message)

    case :emqtt.publish(pid, topic, payload) do
      :ok ->
        Logger.info("EMQTT: successfully published message to: #{topic}")

      {:error, reason} ->
        Logger.error("EMQTT: failed to publish message to: #{topic} reason: #{reason}")
    end
  end

  def handle_call({:publish_message, {topic, message}}, _, st) do
    publish_to_topic(st.pid, topic, message)
    {:reply, :ok, st}
  end

  def handle_cast({:publish_message, {topic, message}}, st) do
    publish_to_topic(st.pid, topic, message)
    {:noreply, st}
  end

  def call(request) do
    GenServer.call(__MODULE__, {:publish_message, request})
  end

  def cast(request) do
    GenServer.cast(__MODULE__, {:publish_message, request})
  end
end
