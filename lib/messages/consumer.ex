defmodule PhxPlatformUtils.Messages.Consumer do
  @behaviour GenRMQ.Consumer

  defp build_ssl_options() do
    ca_cert = :certifi.cacertfile()
    [ssl_options: [cacertfile: ca_cert, verify: :verify_none]]
  end

  def init() do
    config = Application.get_env(:amqp, :config)
    ssl_options = if config[:use_ssl], do: build_ssl_options(), else: []
    uri_options = [username: config[:user], password: config[:pass], host: config[:host], port: config[:port]]
    connection = Keyword.merge(uri_options, ssl_options)
    keys = config[:subscriptions] |> Enum.map(fn x -> x.topic end)

    [
      connection: connection,
      queue: config[:queue],
      exchange: "amq.topic",
      routing_key: keys,
      prefetch_count: "10",
      deadletter_exchange: "custom_deadletter_exchange"
    ]
  end

  def handle_message(%GenRMQ.Message{} = message) do
    config = Application.get_env(:amqp, :config)
    subs = config[:subscriptions]
    matches = Enum.filter(subs, fn sub -> sub.topic == message.attributes.routing_key end)
    decoded = Jason.decode!(message.payload)
    Enum.each(matches, fn match -> match.handler.(decoded, nil) end)
    GenRMQ.Consumer.ack(message)
  end

  def handle_error(%GenRMQ.Message{} = message, _reason), do: GenRMQ.Consumer.reject(message, false)

  def consumer_tag(), do: ""

  def start_link(_opts), do: GenRMQ.Consumer.start_link(__MODULE__, name: __MODULE__)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
