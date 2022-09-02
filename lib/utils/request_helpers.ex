defmodule PhxPlatformUtils.Utils.RequestHelpers do
  def recursively_atomize(list) when is_list(list) do
    list
    |> Enum.map(&recursively_atomize(&1))
  end

  def recursively_atomize(map) when is_map(map) and not is_struct(map) do
    map
    |> Enum.map(fn {key, value} -> {String.to_atom(key), recursively_atomize(value)} end)
    |> Enum.into(%{})
  end

  def recursively_atomize(any), do: any

  @spec validate(map, map) :: {:error, [%{context: map, message: binary, path: list, type: binary}]} | {:ok, any}
  def validate(params, validation_schema) do
    stripped_params =
      params
      |> Map.take(Map.keys(validation_schema))

    case Joi.validate(stripped_params, validation_schema) do
      {:ok, valid_params} ->
        converted_params =
          valid_params
          |> recursively_atomize()

        {:ok, converted_params}

      other ->
        other
    end
  end

  @pagination_schema %{
    "limit" => [:integer, required: false],
    "page" => [:integer, required: false]
  }

  def validate_with_pagination(params, validation_schema) do
    schema =
      validation_schema
      |> Map.merge(@pagination_schema)

    stripped_params =
      params
      |> Map.take(Map.keys(schema))

    case Joi.validate(stripped_params, schema) do
      {:ok, valid_params} ->
        offset = if valid_params["page"] && valid_params["limit"], do: (valid_params["page"] - 1) * valid_params["limit"], else: nil
        limit = if valid_params["limit"], do: valid_params["limit"], else: nil

        converted_params =
          valid_params
          |> Map.drop(["limit", "page"])
          |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)

        {:ok, converted_params, limit, offset}

      other ->
        other
    end
  end
end
