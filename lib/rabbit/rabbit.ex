defmodule PhxPlatformUtils.Rabbit do
  @defaults [
    subscriptions: [],
    env: :dev,
    port: 5672,
    host: "localhost",
    user: "guest",
    pass: "guest",
  ]

  @callback config(Keyword.t()) :: Keyword.t()

  @callback start_link(opts :: Keyword.t()) ::
              {:ok, pid}
              | {:error, {:already_started, pid}}
              | {:error, term}

  @callback init(config :: Keyword.t()) :: Keyword.t()

  def parse_config(app, module, opts \\ []) do
    @defaults
    |> Keyword.merge(Application.get_env(app, module, []))
    |> Keyword.merge(opts)
    |> Keyword.update(:port, 5762, fn val ->
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
        PhxPlatformUtils.Rabbit.parse_config(@otp_app, __MODULE__, opts)
      end

      @impl behaviour
      def start_link(opts \\ []) do
        config = config()

        if config[:env] == :test do
          {:ok, :c.pid(0, 250, 0)}
        else
          PhxPlatformUtils.Rabbit.Client.start_link(config)
        end
      end

      @impl behaviour
      def init(opts) do
        opts
      end

      def publish_sync(topic, payload \\ %{}) do
        PhxPlatformUtils.Rabbit.Client.call({topic, payload})
      end

      def publish_async(topic, payload \\ %{}) do
        PhxPlatformUtils.Rabbit.Client.cast({topic, payload})
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
