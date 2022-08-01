defmodule Mix.Dn.Rebuild do
  def parse_updated_schema(schema_module, opts) do
    # get existing model
    basename = Phoenix.Naming.underscore(schema_module)
    ctx_app = opts[:context_app] || Mix.Phoenix.context_app()
    Mix.Dn.context_lib_path(ctx_app, basename <> "/model.ex")
    |> File.read()
    |>clean_model_file()
  end

  defp parse_schema(field_list) do
    Enum.reduce(field_list, [], fn (field, parsed_list) ->
      # TODO: add additional logic for enum type
      # TODO: will need to handle multi line, typically many_to_many but could be others
      cond do
        String.starts_with?(field, "field") ->
          # parse "field's"
          [name, type] = Regex.run(~r/^field :(\S+), (.+)$/, field, [capture: :all_but_first])
          cond  do
            String.ends_with?(type, "Ecto.UUID") ->
              ["#{name}:uuid" | parsed_list]
            String.starts_with?(type, ":") ->
              ["#{name}#{type}" | parsed_list]
            String.starts_with?(type, "{") ->
              ["#{name}#{String.replace(type, [",", " ", "{", "}"], "")}" | parsed_list]
            true ->
              # TODO: handle no type match
              IO.puts("Error, no type match for#{type}")
          end
        String.starts_with?(field, "belongs_to") ->
          # parse belongs_to relation
          # TODO: better account for pluralization of owner
          case String.split(field, ",") do
            [relation, _, extra] ->
              [key] = Regex.run(~r/^ foreign_key: :(\S+)$/, extra, [capture: :all_but_first])
              IO.inspect(String.replace(relation, " ", ""))
              ["#{key}:#{String.replace(relation, " ", "")}" | parsed_list]
            [relation, _] ->
              IO.inspect(String.replace(relation, " ", ""))
              ["#{String.replace(relation, " ", "")}" | parsed_list]
          end
        String.starts_with?(field, "soft_delete_schema") ->
          ["--soft-delete" | parsed_list]
        true ->
          IO.inspect("what are we doing here? #{field}")
          # TODO: and cases for other relation types, enum, and a catch case then update factory template for other relations
      end
    end)
  end

  defp parse_changeset(changeset_list) do
    Enum.reduce(changeset_list, {[], [], []}, fn (line, {required, unique, foreign_key}) ->
      cond do
        String.starts_with?(line, "|> cast(") ->
          {required, unique, foreign_key}
        String.starts_with?(line, "|> validate_required") ->
          [required_fields_str] = Regex.run(~r/\|\> validate_required\(\[(.+)\]\)/, line, [capture: :all_but_first])
          required_list = String.split(String.replace(required_fields_str, [":", " "], ""), ",")
          {required_list, unique, foreign_key}
        String.starts_with?(line, "|> foreign_key_constraint(") ->
          [fk_con] = Regex.run(~r/\|\> foreign_key_constraint\((.+)\)/, line, [capture: :all_but_first])
          {fk, opts} = String.split(fk_con, ",", [parts: 2])
          {required, unique, foreign_key ++ [{fk, opts}]}
        String.starts_with?(line, "|> unique_constraint(") ->
          [unique] = Regex.run(~r/\|\> unique_constraint\((.+)\)/, line, [capture: :all_but_first])
          {unique, opts} = String.split(unique, ",", [parts: 2])
          {required, unique ++ [{unique, opts}], foreign_key}
      end
    end)
  end

  defp clean_schema(schema_lines) do
    Enum.reduce(schema_lines, {[], nil}, fn (line, {new_list, memo}) ->
      cond do
        memo == nil && String.starts_with?(line, ["field", "belongs_to", "has_one", "has_many", "many_to_many", "soft_delete"]) ->
          {new_list, line}
        memo != nil && String.starts_with?(line, ["field", "belongs_to", "has_one", "has_many", "many_to_many", "soft_delete"]) ->
          {new_list ++ [memo], line}
        memo != nil && String.starts_with?(line, "timestamps") ->
          {new_list ++ [memo], nil}
        memo != nil && !String.starts_with?(line, ["field", "belongs_to", "has_one", "has_many", "many_to_many", "soft_delete"]) ->
          {new_list, memo <> line}
      end
    end)
  end

  defp clean_changeset(changeset_lines) do
    Enum.reduce(changeset_lines, {[], nil}, fn (line, {new_list, memo}) ->
      cond do
        memo == nil && !String.starts_with?(line, "|>") ->
          {new_list, nil}
        memo == nil && String.starts_with?(line, "|>") ->
          {new_list, line}
        memo != nil && String.starts_with?(line, "|>") ->
          {new_list ++ [memo], line}
        memo != nil && !String.starts_with?(line, "|>") ->
          {new_list, memo <> line}
      end
    end)
  end

  defp clean_model_file({_, file_as_string}) do
    String.split(file_as_string, "\n", trim: :true)
      |> split_changeset_and_schema()
      |> parse_and_combine_schema_with_constraints()
  end

  defp parse_and_combine_schema_with_constraints({change_set, schema, _}) do
    {cleaned_schema, _} = clean_schema(schema)
    parsed_schema = parse_schema(cleaned_schema)
    {cleaned_changeset, _} = clean_changeset(change_set)
    parsed_changeset = parse_changeset(cleaned_changeset)
    combine_schema_with_constraints(parsed_schema, parsed_changeset)
  end

  defp combine_schema_with_constraints(schema, {requires, uniques, redacts}) do
    Enum.map(schema, fn column ->
      [name | _] = String.split(column, ":")
      required? = Enum.find_value(requires, & &1 == name)
      unique? = Enum.find_value(uniques, & &1 == name)
      redact? = Enum.find_value(redacts, & &1 == name)
      "#{column}#{if required?, do: "\:required"}#{if unique?, do: "\:unique"}#{if redact?, do: "\:redact"}"
    end)
  end

  defp split_changeset_and_schema(line_list) do
    Enum.reduce(line_list, {[], [], :discard}, fn (line, {change_set, schema, instructions}) ->
      trimmed = String.trim_leading(line)
      end_of_struct? = trimmed == "end"
      new_schema? = String.starts_with?(trimmed, "schema")
      new_changeset? = String.starts_with?(trimmed, "def changeset")
      case instructions do
        :discard ->
          new_instructions = if new_schema?, do: :schema, else: if new_changeset?, do: :change_set, else: :discard
          {change_set, schema, new_instructions}
        :schema ->
          if end_of_struct?, do: {change_set, schema, :discard}, else: {change_set, schema ++ [trimmed], :schema}
        :change_set ->
          if end_of_struct?, do: {change_set, schema, :discard}, else: {change_set ++ [trimmed], schema, :change_set}
      end
    end)
  end
end
