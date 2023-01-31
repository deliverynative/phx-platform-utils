defmodule PhxPlatformUtils.Utils.Token do
  alias PhxPlatformUtils.Errors

  def claims(conn) do
    base = conn.assigns[:user] || %{}

    override_email = base |> Map.get(:"https://deliverynative.com/email", nil)

    if override_email != nil do
      base
      |> Map.merge(%{email: override_email})
      |> Map.delete(:"https://deliverynative.com/email")
    else
      base
    end
  end

  def get_matching_permissions(conn, allowed_permissions) do
    allowed = allowed_permissions |> MapSet.new() |> MapSet.put("sys:admin")

    conn
    |> claims()
    |> Map.get(:permissions, [])
    |> MapSet.new()
    |> MapSet.intersection(allowed)
    |> MapSet.to_list()
  end

  def has_permission!(conn, allowed_permissions) do
    matching = get_matching_permissions(conn, allowed_permissions)

    if length(matching) < 1 do
      raise Errors.Forbidden
    end
  end
end
