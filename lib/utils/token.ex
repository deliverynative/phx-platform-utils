defmodule PhxPlatformUtils.Utils.Token do
  alias PhxPlatformUtils.Errors

  def claims(conn) do
    conn.assigns[:user] || %{}
  end

  def get_matching_permissions(conn, allowed_permissions) do
    allowed = allowed_permissions |> MapSet.new()

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
