defmodule PhxPlatformUtils.Logger.ObanLogOverride do
  @moduledoc """
    Gives access to the ObanLogger module:
    > ObanLogger.info("This message will have all the job data in it")

  """
  defmacro __using__(_opts) do
    quote do
      require Logger
      require PhxPlatformUtils.Logger.ObanJSON
      alias PhxPlatformUtils.Logger.ObanJSON, as: ObanLogger
    end
  end
end
