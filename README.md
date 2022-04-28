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
