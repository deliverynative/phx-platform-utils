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
      {:castore, ">= 0.0.0"},
      {:certifi, "~> 2.8"},
      {:ecto_soft_delete, "~> 2.0"},
      {:ecto_sql, "~> 3.6"},
      {:faker, "~> 0.17"},
      {:gen_rmq, "~> 4.0"},
      {:httpoison, "~> 1.8"},
      {:inflex, "~> 2.0.0"},
      {:jason, "~> 1.2"},
      {:joi, "~> 0.2.1"},
      {:logger_json, "~> 5.1"},
      {:phoenix, "~> 1.6.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:redix, "~> 1.1"}
    ]
  end
end
