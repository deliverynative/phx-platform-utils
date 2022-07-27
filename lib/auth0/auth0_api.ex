defmodule PhxPlatformUtils.Auth0.Auth0Api do
  require Logger
  require Redix
  alias PhxPlatformUtils.Auth0.Auth0Client

  @spec get_access_token! :: any
  def get_access_token!(type \\ :gateway) do
    {:ok, conn} = Redix.start_link("redis://#{Application.get_env(:phx_platform_utils, :redis_url)}:#{Application.get_env(:phx_platform_utils, :redis_port)}")
    redis_result = Redix.command(conn, ["GET", "phx_platform_utils_access_token_#{type}"])
    Redix.stop(conn)

    case redis_result do
      {:ok, nil} ->
        Logger.info("No existing auth0 access token from redis, will retrieve from Auth0")
        get_access_token_and_set!(type)

      {:ok, token} ->
        Logger.info("Successfully retrieved existing auth0 access token from redis")
        token

      _ ->
        Logger.error("Could not successfully retrieve access token from Redis")
    end
  end

  def get_access_token_and_set!(type \\ :gateway) do
    audience =
      if type == :gateway,
        do: Application.get_env(:phx_platform_utils, :auth0_api_audience),
        else: Application.get_env(:phx_platform_utils, :auth0_management_api_audience)

    body = %{
      audience: audience,
      grant_type: "client_credentials",
      client_id: Application.get_env(:phx_platform_utils, :auth0_api_client_id),
      client_secret: Application.get_env(:phx_platform_utils, :auth0_api_client_secret)
    }

    case Auth0Client.post("/oauth/token", body, [
           {"Content-Type", "application/json"}
         ]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Logger.info("Successfully retrieved new auth0 access token from Auth0Api")

        {:ok, conn} =
          Redix.start_link("redis://#{Application.get_env(:phx_platform_utils, :redis_url)}:#{Application.get_env(:phx_platform_utils, :redis_port)}")

        Redix.command(conn, ["SET", "phx_platform_utils_access_token_#{type}", body.access_token])
        Redix.stop(conn)
        body.access_token

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        raise("Unexpected status code from auth0 access token route #{status_code} with body '#{body}'")

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error(reason)
        raise("Error on request for auth0 access token with reason: #{reason}")
    end
  end

  def get_user!(id) do
    access_token = get_access_token!(:management)

    headers = [
      {"Content-Type", "Application/json"},
      Authorization: "Bearer #{access_token}",
      Accept: "Application/json; Charset=utf-8"
    ]

    case Auth0Client.get("/api/v2/users/#{id}", headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        raise("Unexpected status code from auth0 access token route #{status_code} with body '#{Jason.encode!(body)}'")

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error(reason)
        raise("Error on request for auth0 access token with reason: #{reason}")
    end
  end

  def remove_stored_access_token!(type \\ :gateway) do
    {:ok, conn} = Redix.start_link("redis://#{Application.get_env(:phx_platform_utils, :redis_url)}:#{Application.get_env(:phx_platform_utils, :redis_port)}")
    Redix.command!(conn, ["DEL", "phx_platform_utils_access_token_#{type}"])
    Redix.stop(conn)
    Logger.info("Successfully removed existing auth0 access token from redis")
  end
end
