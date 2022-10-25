defmodule Mix.Tasks.Dn.Setup.Jobs do
  @shortdoc "Generates the required migration for DN Exq job runner setup"

  @moduledoc """
  Generates the required migration for DN Exq job runner setup.
  """

  use Mix.Task
  alias Mix.Tasks.Ecto.Gen.Migration

  def colorize(message, opts \\ []) do
    text = opts |> Keyword.get(:text)
    bg = opts |> Keyword.get(:bg)

    bg_color =
      case bg do
        :cyan -> IO.ANSI.cyan_background()
        :red -> IO.ANSI.red_background()
        :magenta -> IO.ANSI.magenta_background()
        :green -> IO.ANSI.green_background()
        :white -> IO.ANSI.white_background()
        _ -> IO.ANSI.default_background()
      end

    text_color =
      case text do
        :cyan -> IO.ANSI.cyan()
        :red -> IO.ANSI.red()
        :magenta -> IO.ANSI.magenta()
        :green -> IO.ANSI.green()
        :black -> IO.ANSI.black()
        _ -> IO.ANSI.default_color()
      end

    bg_color <> text_color <> message <> IO.ANSI.reset()
  end

  def run(_args) do
    IO.puts(colorize("Generating migration for DN Exq job runner setup...", text: :cyan))
    [path] = Migration.run(["add_job_executions_table"])

    middle =
      "def change do\n    create table(:job_executions) do\n      add :attempt, :integer\n      add :completed_at, :utc_datetime_usec\n      add :encoded_parameters, :string\n      add :hash, :string\n      add :job_name, :string\n      add :succeeded, :boolean\n      timestamps()\n    end\n\n    create unique_index(:job_executions, [:hash, :attempt])\n  end\n"

    [first, last] =
      File.read!(path)
      |> String.split("def change do\n\n  end")

    File.write!(path, first <> middle <> last)
    IO.puts(colorize("Migration generated at ", text: :cyan) <> IO.ANSI.underline() <> colorize(path, text: :green))
    spacer = colorize("\n\n*  *  *  *  *  *\n\n", text: :magenta)

    formatted_text =
      colorize("Be sure to run ", text: :white, bg: :black) <>
        IO.ANSI.underline() <>
        colorize("mix.ecto.migrate", text: :cyan, bg: :black) <>
        colorize(" to create the job_executions table!", text: :white, bg: :black)

    IO.puts(spacer <> formatted_text <> spacer)
  end
end
