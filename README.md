# PhxPlatformUtils

This package expands the available `mix phx.gen` commands, adding:

- `mix phx.gen.dn.schema`
- `mix phx.gen.dn.context`

This will create entities in a particular directory structure:

```
lib/
-- application_name/
----- context_name/
-------- resource_name/
----------- factory.ex
----------- model.ex
----------- service.ex
----------- test.exs
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `phx_platform_utils` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phx_platform_utils, git: "https://github.com/deliverynative/phx-platform-utils", tag: "0.2.0"}
  ]
end
```

## Usage

It's recommended to use the `context` generation function for most APIs:

`mix phx.gen.dn.context PascalCaseContext PascalCaseSingularResource snake_cased_pluraized_resources snake_case_table_column:datatype`

Run `mix help phx.gen.dn.context` for more info!

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/phx_platform_utils>.

## RabbitMQ

Instructions for using the rabbit client:

1. Create an rabbit module in your application
  * example: `/lib/order_platform/rabbit.ex`
    ```elixir
      defmodule OrdersPlatform.Rabbit do
          use PhxPlatformUtils.Rabbit, otp_app: :orders_platform
      end
    ```

2. Create a handlers directory/module and add your handler functions.
  * Example: `/lib/consumers`
  * Each handler should be its own module under `Consumers.<handler>` and have a public handler function,
    you will link that function to its subscription via the config file.
  * Your handler function will be given two arguments. The first will be the payload from the message
    and the second will be a properties map of the message. The topic that was published to can be found at props.routing_key.

3. Add your rabbit module as a child of your app in `application.ex` 

4. Add your connection info to your runtime file.
  * env is used to skip startup on a test env
  * Example:
    ```elixir
    config :orders_platform, OrdersPlatform.Rabbit,
      host: System.get_env("RABBITMQ_HOST"),
      port: System.get_env("RABBITMQ_PORT"),
      user: System.get_env("RABBITMQ_USER"),
      pass: System.get_env("RABBITMQ_PASS")
    ```
  

5. Add your subscriptions, handlers, and env to your config file.
  * Subscriptions is a list of maps.
  * Each map needs to have a topic key, which has a string of the topic that you want to subscribe to.
  * Each map also needs a handler key, which has points to you handler function.
  * example:
    ```elixir
    config :orders_platform, OrdersPlatform.Rabbit,
      env: config_env(),
      subscriptions: [
      %{topic: "*.*.orders.test", handler: &Handlers.HandleIncomingOrderEvent/2}
      ]
    ```

6. To publish a message, the client exposes two functions, `publish_sync` and `publish_async`.
  * `publish_sync` will wait for a response, currently this will still always return `{:ok}`
  * `publish_async` will always return `{:ok}`
  * Both functions take two arguments, the first is a string value of the topic you wish to publish two and the second is the message you want to send
  * Example: 
    ```elixir
      Rabbit.publish_async("2b5c86c5-6f68-40be-b6e5-e65dbe0418d6.2b5c86c5-6f68-40be-b6e5-e65dbe0418d6.orders.test", %{order_id: "2b5c86c5-6f68-40be-b6e5-e65dbe0418d6"})
      Rabbit.publish_sync("2b5c86c5-6f68-40be-b6e5-e65dbe0418d6.2b5c86c5-6f68-40be-b6e5-e65dbe0418d6.orders.test", %{order_id: "2b5c86c5-6f68-40be-b6e5-e65dbe0418d6"})
    ```


