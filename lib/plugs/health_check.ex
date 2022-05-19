defmodule PhxPlatformUtils.Plugs.HealthCheck do
  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{request_path: "/hc"} = conn, _opts) do
    conn
    |> send_resp(200, "OK Computer")
    |> halt()
  end

  def call(conn, _opts), do: conn
end
