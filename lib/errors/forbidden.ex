defmodule PhxPlatformUtils.Errors.Forbidden do
  defexception message: "Access not allowed"
end

defimpl Plug.Exception, for: PhxPlatformUtils.Errors.Forbidden do
  def status(_exception), do: 403
  def actions(_), do: []
end
