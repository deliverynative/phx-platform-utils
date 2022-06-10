defmodule PhxPlatformUtils.Utils.RequestHelpers do
  def validate(params, schema) do
    stripped_params = Map.take(params, Map.keys(schema))

    case Joi.validate(stripped_params, schema) do
      {:ok, valid_params} ->
        offset = if valid_params["page"] && valid_params["limit"], do: (valid_params["page"] - 1) * valid_params["limit"], else: nil
        limit = if valid_params["limit"], do: valid_params["limit"], else: nil
        converted_params = Map.drop(valid_params, ["limit", "page"]) |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
        {:ok, converted_params, limit, offset}

      other ->
        other
    end
  end
end
