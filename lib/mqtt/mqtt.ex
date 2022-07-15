defmodule PhxPlatformUtils.Mqtt do
  @defaults [
    client_id: "dev",
    subscriptions: [],
    env: :dev
  ]

  @callback config(Keyword.t()) :: Keyword.t()

  @callback start_link(opts :: Keyword.t()) ::
              {:ok, pid}
              | {:error, {:already_started, pid}}
              | {:error, term}

  @callback init(config :: Keyword.t()) :: Keyword.t()

  # def convert_string_ip_to_tuple(string_ip) do
  #   string_ip
  #   |> String.split(".")
  #   |> Enum.map(fn num ->
  #     {int, _} = Integer.parse(num)
  #     int
  #   end)
  #   |> List.to_tuple()
  # end

  def parse_config(app, module, opts \\ []) do
    @defaults
    |> Keyword.merge(Application.get_env(app, module, []))
    |> Keyword.merge(opts)
    |> Keyword.update(:host, {127, 0, 0, 1}, fn
      ip_string_or_host when is_binary(ip_string_or_host) ->
        if String.match?(ip_string_or_host, ~r/^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$/) do
          ip_string_or_host |> String.to_charlist()
        else
          {:ok, {:hostent, _, _, _, _, [ip_tuple | _]}} = :inet.gethostbyname(String.to_charlist(ip_string_or_host))
          ip = ip_tuple |> Tuple.to_list() |> Enum.join(".")
          IO.inspect(ip)
          ip |> String.to_charlist()
        end

      other_host_type ->
        other_host_type
    end)
    |> Keyword.update(:port, 1883, fn val ->
      if is_binary(val) do
        {port, _} = Integer.parse(val)
        port
      else
        val
      end
    end)
  end

  defmacro __using__(opts) do
    quote bind_quoted: [behaviour: __MODULE__, opts: opts] do
      @otp_app Keyword.fetch!(opts, :otp_app)
      @behaviour behaviour

      @impl behaviour
      def config(opts \\ []) do
        PhxPlatformUtils.Mqtt.parse_config(@otp_app, __MODULE__, opts)
      end

      @impl behaviour
      def start_link(opts \\ []) do
        config = config()

        if config[:env] == :test do
          {:ok, :c.pid(0, 250, 0)}
        else
          PhxPlatformUtils.Mqtt.Client.start_link(config)
        end
      end

      @impl behaviour
      def init(opts) do
        opts
      end

      def publish_sync(topic, payload \\ %{}) do
        PhxPlatformUtils.Mqtt.Client.call({topic, payload})
      end

      def publish_async(topic, payload \\ %{}) do
        PhxPlatformUtils.Mqtt.Client.cast({topic, payload})
      end

      @spec child_spec(Keyword.t()) :: GenServer.child_spec()
      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]}
        }
      end
    end
  end
end
