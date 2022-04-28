defmodule <%= inspect context.module %>.Service do
  import Ecto.Query, warn: false
  alias <%= inspect schema.repo %>
end
