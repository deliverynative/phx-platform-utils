defmodule Mix.Dn.Schema do
  @moduledoc false
  alias Mix.Dn.Args
  alias Mix.Dn.Schema
  alias Mix.Dn.Types

  alias Faker

  defstruct module: nil,
            resource: nil,
            repo: nil,
            table: nil,
            collection: nil,
            embedded?: false,
            generate?: true,
            opts: [],
            alias: nil,
            faker_attrs: nil,
            file: nil,
            attrs: [],
            string_attr: nil,
            plural: nil,
            singular: nil,
            uniques: [],
            redacts: [],
            assocs: [],
            types: [],
            indexes: [],
            defaults: [],
            human_singular: nil,
            human_plural: nil,
            binary_id: false,
            migration_defaults: nil,
            migration?: false,
            params: %{},
            sample_id: nil,
            web_path: nil,
            web_namespace: nil,
            context_app: nil,
            route_helper: nil,
            migration_module: nil,
            fixture_unique_functions: %{},
            fixture_params: %{},
            prefix: nil

  @valid_types [
    :integer,
    :float,
    :decimal,
    :boolean,
    :map,
    :string,
    :array,
    :belongs_to,
    :has_many,
    :has_one,
    :many_to_many,
    :text,
    :date,
    :time,
    :time_usec,
    :naive_datetime,
    :naive_datetime_usec,
    :utc_datetime,
    :utc_datetime_usec,
    :uuid,
    :binary,
    :enum
  ]

  def valid_types, do: @valid_types

  def valid?(schema) do
    schema =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/
  end

  def new(schema_name, schema_plural, cli_attributes, opts) do
    ctx_app = opts[:context_app] || Mix.Phoenix.context_app()
    otp_app = Mix.Phoenix.otp_app()
    opts = Keyword.merge(Application.get_env(otp_app, :generators, []), opts)
    base = Mix.Phoenix.context_base(ctx_app)
    basename = Phoenix.Naming.underscore(schema_name)
    module = Module.concat([base, schema_name])
    repo = opts[:repo] || Module.concat([base, "Repo"])
    file = Mix.Dn.context_lib_path(ctx_app, basename <> "/model.ex")
    table = opts[:table] || schema_plural
    {extracted_attributes, uniques, redacts} = Args.extract_attribute_flags(cli_attributes)
    {associations, attributes} = Args.partition_associations_from_attributes(module, Args.parse_attributes(extracted_attributes))
    types = Types.types(attributes)
    web_namespace = opts[:web] && Phoenix.Naming.camelize(opts[:web])
    web_path = web_namespace && Phoenix.Naming.underscore(web_namespace)
    embedded? = Keyword.get(opts, :embedded, false)
    generate? = Keyword.get(opts, :schema, true)

    IO.inspect(assocs)
    IO.puts("!!@#@$)(#$)#($*#)($*")
    IO.inspect(attrs)
    faker_attrs = Enum.map(attrs, &Types.determine_faker_generator_for_type(&1))

    singular_entity_name =
      module
      |> Module.split()
      |> List.last()
      |> Phoenix.Naming.underscore()

    resource_entity_name =
      module
      |> Module.split()
      |> List.last()

    collection = if schema_plural == singular_entity_name, do: singular_entity_name <> "_collection", else: schema_plural
    string_attribute = Args.string_attribute(types)
    create_params = params(attrs, :create)

    default_params_key =
      case Enum.at(create_params, 0) do
        {key, _} -> key
        nil -> :some_field
      end

    fixture_unique_functions = fixture_unique_functions(singular_entity_name, uniques, attrs)

    %Schema{
      opts: opts,
      migration?: Keyword.get(opts, :migration, true),
      module: module,
      resource: resource_entity_name,
      repo: repo,
      table: table,
      embedded?: embedded?,
      alias: module |> Module.split() |> List.last() |> Module.concat(nil),
      file: file,
      attrs: attrs,
      faker_attrs: faker_attrs,
      plural: schema_plural,
      singular: singular,
      collection: collection,
      assocs: assocs,
      types: types,
      defaults: schema_defaults(attrs),
      uniques: uniques,
      redacts: redacts,
      indexes: indexes(table, assocs, uniques),
      human_singular: Phoenix.Naming.humanize(singular),
      human_plural: Phoenix.Naming.humanize(schema_plural),
      binary_id: opts[:binary_id],
      migration_defaults: migration_defaults(attrs),
      string_attr: string_attribute,
      params: %{
        create: create_params,
        update: params(attrs, :update),
        default_key: string_attribute || default_params_key
      },
      web_namespace: web_namespace,
      web_path: web_path,
      route_helper: route_helper(web_path, singular),
      sample_id: sample_id(opts),
      context_app: ctx_app,
      generate?: generate?,
      migration_module: migration_module(),
      fixture_unique_functions: fixture_unique_functions,
      fixture_params: fixture_params(attrs, fixture_unique_functions),
      prefix: opts[:prefix]
    }
  end

  @doc """
  Returns the string value of the default schema param.
  """
  def default_param(%Schema{} = schema, action) do
    schema.params
    |> Map.fetch!(action)
    |> Map.fetch!(schema.params.default_key)
    |> to_string()
  end

  @doc """
  Generates some sample params based on the parsed attributes.
  """
  def params(attrs, action \\ :create) when action in [:create, :update] do
    attrs
    |> Args.reject_relational_attributes()
    |> Enum.into(%{}, fn {attribute_name, type} ->
      {k, Types.type_to_default(attribute_name, type, action)}
    end)
  end

  @doc """
  Converts the given value to map format when it is a date, time, datetime or naive_datetime.

  Since `form_component.html.heex` generated by the live generator uses selects for dates and/or
  times, fixtures must use map format for those fields in order to submit the live form.
  """
  def live_form_value(%Date{} = date), do: %{day: date.day, month: date.month, year: date.year}

  def live_form_value(%Time{} = time), do: %{hour: time.hour, minute: time.minute}

  def live_form_value(%NaiveDateTime{} = naive),
    do: %{
      day: naive.day,
      month: naive.month,
      year: naive.year,
      hour: naive.hour,
      minute: naive.minute
    }

  def live_form_value(%DateTime{} = naive),
    do: %{
      day: naive.day,
      month: naive.month,
      year: naive.year,
      hour: naive.hour,
      minute: naive.minute
    }

  def live_form_value(value), do: value

  @doc """
  Build an invalid value for `@invalid_attrs` which is nil by default.

  * In case the value is a list, this will return an empty array.
  * In case the value is date, datetime, naive_datetime or time, this will return an invalid date.
  * In case it is a boolean, we keep it as false
  """
  def invalid_form_value(value) when is_list(value), do: []

  def invalid_form_value(%{day: _day, month: _month, year: _year} = date),
    do: %{date | day: 30, month: 02}

  def invalid_form_value(%{hour: _hour, minute: _minute} = value), do: value
  def invalid_form_value(true), do: false
  def invalid_form_value(_value), do: nil

  @doc """
  Generates an invalid error message according to the params present in the schema.
  """
  def failed_render_change_message(schema) do
    if schema.params.create |> Map.values() |> Enum.any?(&date_value?/1) do
      "is invalid"
    else
      "can&#39;t be blank"
    end
  end

  def type_for_migration({:enum, _}), do: :string
  def type_for_migration(other), do: other

  def format_fields_for_schema(schema) do
    Enum.map_join(schema.types, "\n", fn {k, v} ->
      "    field #{inspect(k)}, #{type_and_opts_for_schema(v)}#{schema.defaults[k]}#{maybe_redact_field(k in schema.redacts)}"
    end)
  end

  def type_and_opts_for_schema({:enum, opts}),
    do: ~s|Ecto.Enum, values: #{inspect(Keyword.get(opts, :values))}|

  def type_and_opts_for_schema(other), do: inspect(other)

  def maybe_redact_field(true), do: ", redact: true"
  def maybe_redact_field(false), do: ""

  defp date_value?(%{day: _day, month: _month, year: _year}), do: true
  defp date_value?(_value), do: false

  @doc """
  Returns the string value for use in EEx templates.
  """
  def value(schema, field, value) do
    schema.types
    |> Map.fetch!(field)
    |> inspect_value(value)
  end

  defp inspect_value(:decimal, value), do: "Decimal.new(\"#{value}\")"
  defp inspect_value(_type, value), do: inspect(value)

  @enum_missing_value_error """
  Enum type requires at least one value
  For example:

      mix phx.gen.schema Comment comments body:text status:enum:published:unpublished
  """

  defp schema_defaults(attrs) do
    Enum.into(attrs, %{}, fn
      {key, :boolean} -> {key, ", default: false"}
      {key, _} -> {key, ""}
    end)
  end

  defp indexes(table, assocs, uniques) do
    uniques = Enum.map(uniques, fn key -> {key, true} end)
    assocs = Enum.map(assocs, fn {_, key, _, _} -> {key, false} end)

    (uniques ++ assocs)
    |> Enum.uniq_by(fn {key, _} -> key end)
    |> Enum.map(fn
      {key, false} -> "create index(:#{table}, [:#{key}])"
      {key, true} -> "create unique_index(:#{table}, [:#{key}])"
    end)
  end

  defp migration_defaults(attrs) do
    Enum.into(attrs, %{}, fn
      {key, :boolean} -> {key, ", default: false, null: false"}
      {key, _} -> {key, ""}
    end)
  end

  defp sample_id(opts) do
    if Keyword.get(opts, :binary_id, false) do
      Keyword.get(opts, :sample_binary_id, "11111111-1111-1111-1111-111111111111")
    else
      -1
    end
  end

  defp route_helper(web_path, singular) do
    "#{web_path}_#{singular}"
    |> String.trim_leading("_")
    |> String.replace("/", "_")
  end

  defp migration_module do
    case Application.get_env(:ecto_sql, :migration_module, Ecto.Migration) do
      migration_module when is_atom(migration_module) -> migration_module
      other -> Mix.raise("Expected :migration_module to be a module, got: #{inspect(other)}")
    end
  end

  defp fixture_unique_functions(singular, uniques, attrs) do
    uniques
    |> Enum.filter(&Keyword.has_key?(attrs, &1))
    |> Enum.into(%{}, fn attr ->
      function_name = "unique_#{singular}_#{attr}"

      {function_def, needs_impl?} =
        case Keyword.fetch!(attrs, attr) do
          :integer ->
            function_def = """
              def #{function_name}, do: System.unique_integer([:positive])
            """

            {function_def, false}

          type when type in [:string, :text] ->
            function_def = """
              def #{function_name}, do: "some #{attr}\#{System.unique_integer([:positive])}"
            """

            {function_def, false}

          _ ->
            function_def = """
              def #{function_name} do
                raise "implement the logic to generate a unique #{singular} #{attr}"
              end
            """

            {function_def, true}
        end

      {attr, {function_name, function_def, needs_impl?}}
    end)
  end

  defp fixture_params(attrs, fixture_unique_functions) do
    attrs
    |> Enum.reject(fn
      {_, {:references, _}} -> true
      {_, _} -> false
    end)
    |> Enum.into(%{}, fn {attr, type} ->
      case Map.fetch(fixture_unique_functions, attr) do
        {:ok, {function_name, _function_def, _needs_impl?}} ->
          {attr, "#{function_name}()"}

        :error ->
          {attr, inspect(type_to_default(attr, type, :create))}
      end
    end)
  end
end
