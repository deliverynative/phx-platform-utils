defmodule Mix.Tasks.Dn.Retrieve.Secrets do
  @shortdoc "Retreives secrets for an environment + application combination"

  @moduledoc """
  Retrieves secrets for an application given an environment and an application
  Usage:
    mix dn.retrieve.secrets --env my-environment --app my-app
  """

  use Mix.Task
  alias AWS
  alias Jason

  @switches [
    env: :string,
    app: :string
  ]

  @valid_name ~r/^[A-Za-z0-9][\w-]*[A-Za-z0-9]$/

  @doc false
  def run(args) do
    {:ok, _} = Application.ensure_all_started(:aws_credentials)
    credentials = :aws_credentials.get_credentials()

    aws_client = AWS.Client.create(credentials.access_key_id, credentials.secret_access_key, "us-west-2")

    {parsed_args, _, _} = parse_args(args)

    [env: env, app: app] =
      ensure_args(parsed_args)
      |> validate_args!()

    secret_name = "#{env}-#{app}"

    response =
      case AWS.SecretsManager.get_secret_value(aws_client, %{SecretId: secret_name}) do
        {:ok, res, _} ->
          res

        {:error, err} ->
          IO.inspect(err)
          throw("Received error from AWS.SecretsManager.get_secret_value() invocation")
      end

    secret_result =
      response
      |> Map.new(fn {k, v} -> {String.to_atom(String.downcase(k)), v} end)

    IO.puts("Successfully retrieved #{secret_result.arn} from AWS")

    file_writable_secrets =
      Jason.decode!(secret_result.secretstring, keys: :atoms)
      |> Enum.map(fn {k, v} -> "#{k}=#{v}\n" end)
      |> Enum.join("")

    Mix.Generator.create_file(".env", file_writable_secrets)
  end

  defp parse_args(args) do
    {opts, parsed, invalid} = OptionParser.parse(args, switches: @switches)
    {opts, parsed, invalid}
  end

  defp ensure_args(args) do
    cond do
      Keyword.get(args, :env) == nil ->
        raise_with_help("Environment name (--env) must be provided")

      Keyword.get(args, :app) == nil ->
        raise_with_help("Application name (--app) must be provided")

      true ->
        args
    end
  end

  @dialyzer {:nowarn_function, validate_args!: 1}
  defp validate_args!([env: env, app: app] = args) do
    cond do
      not Regex.match?(@valid_name, env) ->
        raise_with_help("Environment name (--env) must be alphanumeric.\nIt may contain hyphens or underscores, but not beginning or ending with either")

      not Regex.match?(@valid_name, app) ->
        raise_with_help("Application name (--app) must be alphanumeric.\nIt may contain hyphens or underscores, but not beginning or ending with either")

      true ->
        args
    end
  end

  @dialyzer {:nowarn_function, raise_with_help: 1}
  defp raise_with_help(msg) do
    Mix.raise("""
    #{msg}

    mix dn.retrieve.secrets must be called with an environment name and an application name:
        mix dn.retrive.secrets --env production --app bazinga-platform
        mix dn.retrive.secrets --env staging_2 --app api_goatway
    The environment must be entirely alphanumeric with only hyphens "-" or underscores "_", but not beginning or ending with either
    The application must be entirely alphanumeric with only hyphens "-" or underscores "_", but not beginning or ending with either
    The result of \#{env}-\#{app} should be an existing AWS Secrets Manager secret that the caller is authorized to access
    """)
  end
end
