defmodule PhxPlatformUtils.Errors.ResourceNotFound do
  defexception message: "Resource not found"
end

defimpl Plug.Exception, for: PhxPlatformUtils.Errors.ResourceNotFound do
  def status(_exception), do: 404
  def actions(_), do: []
end
