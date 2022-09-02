defmodule PhxPlatformUtils.Utils.Token do
  alias PhxPlatformUtils.Errors

  def claims(conn) do
    base = conn.assigns[:user] || %{}

    base
    |> Map.merge(%{
      email: Map.get(base, :"https://deliverynative.com/email")
    })
    |> Map.delete(:"https://deliverynative.com/email")
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
