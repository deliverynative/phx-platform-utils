defmodule PhxPlatformUtils.Utils.Token do
  alias PhxPlatformUtils.Errors

  def claims(conn) do
    conn.assigns[:user]
  end

  def get_matching_permissions(conn, allowed_permissions) do
    allowed = MapSet.new(allowed_permissions)
    users_perms = MapSet.new(claims(conn).permissions)
    MapSet.intersection(allowed, users_perms) |> MapSet.to_list()
  end

  def has_permission!(conn, allowed_permissions) do
    matching = get_matching_permissions(conn, allowed_permissions)

    if length(matching) < 1 do
      raise Errors.Forbidden
    end
  end
end
