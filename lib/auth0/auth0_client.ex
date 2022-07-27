defmodule PhxPlatformUtils.Auth0.Auth0Client do
  use HTTPoison.Base
  require Logger

  def process_request_url(url) do
    Application.get_env(:phx_platform_utils, :auth0_api_url) <> url
  end

  def process_request_body(body) do
    if is_map(body) do
      body
      |> Enum.filter(fn {_, v} -> v != nil end)
      |> Enum.into(%{})
      |> Jason.encode!()
    else
      body
    end
  end

  def process_response_body(body) do
    try do
      body
      |> Jason.decode!(keys: :atoms)
    rescue
      _ ->
        body
    end
  end
end
