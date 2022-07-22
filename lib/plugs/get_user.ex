defmodule PhxPlatformUtils.Plugs.GetUser do
  import Plug.Conn
  require Jason

  def init(opts), do: opts

  def call(conn, _opts) do
    user =
      conn
      |> get_token!()
      |> decode_token!()

    assign(conn, :user, user)
  end

  defp get_token!(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end

  defp decode_token!(nil) do
    nil
  end

  defp decode_token!(token) do
    [_, payload, _] = token |> String.split(".")
    payload |> Base.decode64!(padding: false) |> Jason.decode!(keys: :atoms)
  end
end
