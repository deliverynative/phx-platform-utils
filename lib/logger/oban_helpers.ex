defmodule PhxPlatformUtils.Logger.ObanHelpers do
  require Logger

  def get_relevant_job_fields(job) do
    job
    |> Map.take([:attempt, :args, :attempted_at, :id, :queue, :worker])
  end

  def telemetry_logging_handler([:oban, :job, type], meta, execution_data, nil) do
    duration = meta |> Map.get(:duration, nil)

    error_data =
      execution_data
      |> Map.take([:kind, :reason, :stacktrace])

    job_data =
      execution_data
      |> Map.get(:job, %{})
      |> get_relevant_job_fields()

    other_data =
      execution_data
      |> Map.take([:state, :result])

    oban_meta =
      job_data
      |> Map.merge(other_data)
      |> Map.merge(error_data)
      |> Map.merge(%{duration: duration})

    metadata = [oban: oban_meta]

    case type do
      :start -> Logger.info("Job started", metadata)
      :stop -> Logger.info("Job started", metadata)
      :exception -> Logger.error("Job failed", metadata)
    end
  end
end
