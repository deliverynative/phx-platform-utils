defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>Controller do
  use <%= inspect context.web_module %>, :controller
  alias PhxPlatformUtils.Utils.Token
  alias PhxPlatformUtils.Utils.RequestHelpers

  alias <%= inspect context.module %>.{Model, Service}

  action_fallback <%= inspect context.web_module %>.FallbackController

  def index(conn, _params) do
    Token.has_permission!(conn, ["<%= schema.plural %>:read"])
    <%= schema.plural %> = Service.list_<%= schema.plural %>()
    render(conn, "index.json", <%= schema.plural %>: <%= schema.plural %>)
  end

  def create(conn, %{<%= inspect schema.singular %> => <%= schema.singular %>_params}) do
    Token.has_permission!(conn, ["<%= schema.plural %>:write"])

    with {:ok, %Model{} = <%= schema.singular %>} <- Service.create_<%= schema.singular %>(<%= schema.singular %>_params) do
      conn
      |> put_status(:created)
      |> render("show.json", <%= schema.singular %>: <%= schema.singular %>)
    end
  end

  def show(conn, %{"id" => id}) do
    Token.has_permission!(conn, ["<%= schema.plural %>:read"])

    <%= schema.singular %> = Service.get_<%= schema.singular %>!(id)
    render(conn, "show.json", <%= schema.singular %>: <%= schema.singular %>)
  end

  def update(conn, %{"id" => id, <%= inspect schema.singular %> => <%= schema.singular %>_params}) do
    Token.has_permission!(conn, ["<%= schema.plural %>:write"])

    <%= schema.singular %> = Service.get_<%= schema.singular %>!(id)

    with {:ok, %Model{} = <%= schema.singular %>} <- Service.update_<%= schema.singular %>(<%= schema.singular %>, <%= schema.singular %>_params) do
      render(conn, "show.json", <%= schema.singular %>: <%= schema.singular %>)
    end
  end

  def delete(conn, %{"id" => id}) do
    Token.has_permission!(conn, ["<%= schema.plural %>:write"])

    <%= schema.singular %> = Service.get_<%= schema.singular %>!(id)

    with {:ok, %Model{}} <- Service.delete_<%= schema.singular %>(<%= schema.singular %>) do
      send_resp(conn, :no_content, "")
    end
  end
end
