defmodule PhxPlatformUtils.Logger.ObanJSON do
  @moduledoc """
    Extends Oban Jobs to add important job execution metadata to logs.
  """
  alias PhxPlatformUtils.Logger.ObanHelpers

  defmacro error(msg, additional_meta \\ nil) do
    extra_meta =
      quote do
        if(unquote(additional_meta) != nil, do: unquote(additional_meta), else: %{})
      end

    if Macro.Env.has_var?(__CALLER__, {:job, nil}) do
      quote do
        important_meta =
          var!(job)
          |> Map.from_struct()
          |> ObanHelpers.get_relevant_job_fields()

        Logger.error(unquote(msg), oban: important_meta, extras: unquote(extra_meta))
      end
    else
      quote do
        Logger.error(unquote(msg), extras: unquote(extra_meta))
      end
    end
  end

  defmacro info(msg, additional_meta \\ nil) do
    extra_meta =
      quote do
        if(unquote(additional_meta) != nil, do: unquote(additional_meta), else: %{})
      end

    if Macro.Env.has_var?(__CALLER__, {:job, nil}) do
      quote do
        important_meta =
          var!(job)
          |> Map.from_struct()
          |> ObanHelpers.get_relevant_job_fields()

        Logger.info(unquote(msg), oban: important_meta, extras: unquote(extra_meta))
      end
    else
      quote do
        Logger.info(unquote(msg), extras: unquote(extra_meta))
      end
    end
  end

  defmacro debug(msg, additional_meta \\ nil) do
    extra_meta =
      quote do
        if(unquote(additional_meta) != nil, do: unquote(additional_meta), else: %{})
      end

    if Macro.Env.has_var?(__CALLER__, {:job, nil}) do
      quote do
        important_meta =
          var!(job)
          |> Map.from_struct()
          |> ObanHelpers.get_relevant_job_fields()

        Logger.debug(unquote(msg), oban: important_meta, extras: unquote(extra_meta))
      end
    else
      quote do
        Logger.debug(unquote(msg), extras: unquote(extra_meta))
      end
    end
  end

  defmacro log(level, msg, additional_meta \\ nil) do
    extra_meta =
      quote do
        if(unquote(additional_meta) != nil, do: unquote(additional_meta), else: %{})
      end

    if Macro.Env.has_var?(__CALLER__, {:job, nil}) do
      quote do
        important_meta =
          var!(job)
          |> Map.from_struct()
          |> ObanHelpers.get_relevant_job_fields()

        Logger.log(unquote(level), unquote(msg), oban: important_meta, extras: unquote(extra_meta))
      end
    else
      quote do
        Logger.log(unquote(level), unquote(msg), extras: unquote(extra_meta))
      end
    end
  end
end
