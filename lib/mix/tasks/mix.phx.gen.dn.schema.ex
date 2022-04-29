defmodule Mix.Tasks.Phx.Gen.Dn.Schema do
  @shortdoc "Generates an Ecto schema and migration file in DN format"
  use Mix.Task
  alias Mix.Dn.Schema

  @switches [
    migration: :boolean,
    binary_id: :boolean,
    table: :string,
    web: :string,
    context_app: :string,
    prefix: :string
  ]

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise(
        "mix phx.gen.schema must be invoked from within your *_web application root directory"
      )
    end

    schema = build(args, [])
    paths = Mix.Dn.generator_paths()
    prompt_for_conflicts(schema)

    schema
    |> copy_new_files(paths, schema: schema)

    # |> print_shell_instructions()
  end

  defp prompt_for_conflicts(schema) do
    schema
    |> files_to_be_generated()
    |> Mix.Dn.prompt_for_conflicts()
  end

  @doc false
  def build(args, parent_opts, help \\ __MODULE__) do
    {schema_opts, parsed, _} = OptionParser.parse(args, switches: @switches)
    [schema_name, plural | attrs] = validate_args!(parsed, help)

    opts =
      parent_opts
      |> Keyword.merge(schema_opts)
      |> put_context_app(schema_opts[:context_app])

    schema = Schema.new(schema_name, plural, attrs, opts)

    schema
  end

  defp put_context_app(opts, nil), do: opts

  defp put_context_app(opts, string) do
    Keyword.put(opts, :context_app, String.to_atom(string))
  end

  @doc false
  def files_to_be_generated(%Schema{} = schema) do
    [{:eex, "model.ex", schema.file}]
  end

  @doc false
  def copy_new_files(%Schema{context_app: ctx_app} = schema, paths, binding) do
    files = files_to_be_generated(schema)
    Mix.Dn.copy_from(paths, "priv/templates/phx.gen.dn.schema", binding, files)

    if schema.migration? do
      migration_path =
        Mix.Dn.context_app_path(
          ctx_app,
          "priv/repo/migrations/#{timestamp()}_create_#{schema.table}.exs"
        )

      Mix.Dn.copy_from(paths, "priv/templates/phx.gen.dn.schema", binding, [
        {:eex, "migration.exs", migration_path}
      ])
    end

    schema
  end

  @doc false
  def print_shell_instructions(%Schema{} = schema) do
    if schema.migration? do
      Mix.shell().info("""
      Remember to update your repository by running migrations:
          $ mix ecto.migrate
      """)
    end
  end

  @doc false
  def validate_args!([schema, plural | _] = args, help) do
    cond do
      not Schema.valid?(schema) ->
        help.raise_with_help(
          "Expected the schema argument, #{inspect(schema)}, to be a valid module name"
        )

      String.contains?(plural, ":") or plural != Phoenix.Naming.underscore(plural) ->
        help.raise_with_help(
          "Expected the plural argument, #{inspect(plural)}, to be all lowercase using snake_case convention"
        )

      true ->
        args
    end
  end

  def validate_args!(_, help) do
    help.raise_with_help("Invalid arguments")
  end

  @doc false
  @spec raise_with_help(String.t()) :: no_return()
  def raise_with_help(msg) do
    Mix.raise("""
    #{msg}
    mix phx.gen.schema expects both a module name and
    the plural of the generated resource followed by
    any number of attributes:
        mix phx.gen.schema Blog.Post blog_posts title:string
    """)
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)
end
