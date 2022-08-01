defmodule <%= inspect context.web_module %>.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use <%= inspect context.web_module %>, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(<%= inspect context.web_module %>.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, %Ecto.InvalidChangesetError{} = error}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(<%= inspect context.web_module %>.ChangesetView)
    |> render("error.json", changeset: error.changeset)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(<%= inspect context.web_module %>.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, [%Joi.Error{} = head | rest]}) do
    result = [head | rest] |> Enum.map(&Map.take(&1, [:message, :context]))

    conn
    |> put_status(:bad_request)
    |> json(result)
  end

  def call(conn, {:error, %Ecto.ConstraintError{} = error}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(error.message)
  end

  def call(conn, {:error, any}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(any)
  end
end
