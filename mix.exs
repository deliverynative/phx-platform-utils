defmodule PhxPlatformUtils.MixProject do
  use Mix.Project

  def project do
    [
      app: :phx_platform_utils,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:amqp, "~> 3.1"},
      {:certifi, "~> 2.8"},
      {:ecto_sql, "~> 3.6"},
      {:faker, "~> 0.17"},
      {:inflex, "~> 2.0.0"},
      {:jason, "~> 1.2"},
      {:joi, "~> 0.2.1"},
      {:phoenix, "~> 1.6.6"},
      {:phoenix_ecto, "~> 4.4"}
    ]
  end
end
