defmodule PhxPlatformUtils.Messages.Publisher do
  @behaviour GenRMQ.Publisher

  require Logger

  defp build_ssl_options() do
    ca_cert = :certifi.cacertfile()
    [ssl_options: [cacertfile: ca_cert, verify: :verify_none]]
  end

  def start_link(_opts) do
    GenRMQ.Publisher.start_link(__MODULE__, name: __MODULE__)
  end

  def publish(routing_key, message) do
    Logger.info("Publishing message #{inspect(message)}")
    payload = Jason.encode!(message)
    GenRMQ.Publisher.publish(__MODULE__, payload, routing_key)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def init() do
    config = Application.get_env(:amqp, :config)
    ssl_options = if config[:use_ssl], do: build_ssl_options(), else: []
    uri_options = [username: config[:user], password: config[:pass], host: config[:host], port: config[:port]]
    connection = Keyword.merge(uri_options, ssl_options)

    [
      exchange: "amq.topic",
      connection: connection
    ]
  end
end
