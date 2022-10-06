defmodule PhxPlatformUtils.Utils.ScheduledJob do
  alias Crontab.{CronExpression, Scheduler}

  @moduledoc """
    Adds cron last-tick extraction for scheduled jobs utility and passes as meta to the Oban worker.
  """

  defmacro __using__(_opts) do
    quote do
      def execute, do: execute(%{}, [])

      def execute(opts) when is_list(opts), do: execute(%{}, opts)

      def execute(args) when is_map(args), do: execute(args, [])

      def execute(args, opts) do
        last_tick =
          opts
          |> Keyword.get(:cron, "*/1 * * * * *")
          |> CronExpression.Parser.parse!(true)
          |> Scheduler.get_previous_run_date!()
          |> DateTime.from_naive!("Etc/UTC")

        new(args, meta: %{cron_tick: last_tick})
        |> Oban.insert()
      end
    end
  end
end
