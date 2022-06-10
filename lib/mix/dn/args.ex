defmodule Mix.Dn.Args do
  @doc """
  Given a list of attribute pairings, gets appropraitely split flags for {attributes with types, uniques, redacts}
  E.g.       ["my_param:decimal", "my_param:belongs_to:other_table", "donkey_name:string:unique"]
  Becomes:   {["my_param:decimal", "my_param:belongs_to:other_table", "donkey_name:string"], [:donkey_name], []}
  """
  def extract_attribute_flags(cli_attributes) do
    {attributes, uniques, redacts} =
      Enum.reduce(cli_attributes, {[], [], []}, fn attribute, {attributes, uniques, redacts} ->
        [attribute_name | types_and_flags] = String.split(attribute, ":")
        attribute_name = String.to_atom(attribute_name)
        split_flags(Enum.reverse(types_and_flags), attribute_name, attributes, uniques, redacts)
      end)

    {Enum.reverse(attributes), uniques, redacts}
  end

  # Recursively splits flags to strip out :unique and :redact types
  defp split_flags(["unique" | rest], name, attributes, uniques, redacts),
    do: split_flags(rest, name, attributes, [name | uniques], redacts)

  defp split_flags(["redact" | rest], name, attributes, uniques, redacts),
    do: split_flags(rest, name, attributes, uniques, [name | redacts])

  defp split_flags(rest, name, attributes, uniques, redacts),
    do: {[Enum.join([name | Enum.reverse(rest)], ":") | attributes], uniques, redacts}

  @doc """
  Rejects relational attributes from list
  """
  def reject_relational_attributes(attributes) do
    attributes
    |> Enum.reject(fn
      {_, {:belongs_to, _}} -> true
      {_, {:has_one, _}} -> true
      {_, {:has_many, _}} -> true
      {_, {:many_to_many, _}} -> true
      _ -> false
    end)
  end

  @doc """
  Parses the attributes as received by generators.
  """
  def parse_attributes(attributes) do
    Enum.map(attributes, fn attribute ->
      attribute
      |> String.split(":", parts: 3)
      |> list_to_attritbute()
      |> validate_attribute!()
    end)
  end

  #
  defp list_to_attritbute([key]), do: {String.to_atom(key), :string}
  defp list_to_attritbute([key, value]), do: {String.to_atom(key), String.to_atom(value)}

  defp list_to_attritbute([key, comp, value]) do
    {String.to_atom(key), {String.to_atom(comp), String.to_atom(value)}}
  end

  defp validate_attribute!({_name, :enum}), do: Mix.raise(@enum_missing_value_error)
  defp validate_attribute!({_name, type} = attr) when type in @valid_types, do: attr
  defp validate_attribute!({_name, {:enum, _vals}} = attr), do: attr
  defp validate_attribute!({_name, {type, _}} = attr) when type in @valid_types, do: attr

  defp validate_attribute!({_, type}) do
    Mix.raise(
      "Unknown type `#{inspect(type)}` given to generator. " <>
        "The supported types are: #{@valid_types |> Enum.sort() |> Enum.join(", ")}"
    )
  end

  defp validate_attribute!({name, :datetime}), do: validate_attribute!({name, :naive_datetime})

  defp validate_attribute!({name, :array}) do
    Mix.raise("""
    Phoenix generators expect the type of the array to be given to #{name}:array.
    For example:

        mix phx.gen.schema Post posts settings:array:string
    """)
  end

  def partition_associations_from_attributes(schema_module, attributes_with_associations) do
    {association_fields, attribute_fields} =
      Enum.split_with(attributes_with_associations, fn
        {_, {:belongs_to, _}} ->
          true

        {_, {:many_to_many, _}} ->
          true

        {_, {:has_many, _}} ->
          true

        {_, {:has_one, _}} ->
          true

        {key, :belongs_to} ->
          Mix.raise("""
          Phoenix generators expect the table to be given to #{key}:belongs_to.
          For example:

              mix phx.gen.schema Comment comments body:text post_id:belongs_to:posts
          """)

        {key, :many_to_many} ->
          Mix.raise("""
          Phoenix generators expect the table to be given to #{key}:many_to_many.
          For example:

              mix phx.gen.schema Comment comments body:text post_id:many_to_many:posts
          """)

        {key, :has_many} ->
          Mix.raise("""
          Phoenix generators expect the table to be given to #{key}:has_many.
          For example:

              mix phx.gen.schema Comment comments body:text post_id:has_many:posts
          """)

        {key, :has_one} ->
          Mix.raise("""
          Phoenix generators expect the table to be given to #{key}:has_one.
          For example:

              mix phx.gen.schema Comment comments body:text post_id:has_one:posts
          """)

        _ ->
          false
      end)

    associations =
      Enum.map(association_fields, fn {key, {relationship, source}} ->
        base = schema_module |> Module.split() |> Enum.drop(-1)
        aliased = Phoenix.Naming.camelize(Atom.to_string(key))
        module = Module.concat(base ++ [aliased])
        {key, relationship, inspect(module), module, source}
      end)

    {associations, attribute_fields}
  end

  def string_attribute(types) do
    Enum.find_value(types, fn
      {key, :string} -> key
      _ -> false
    end)
  end
end
