defmodule CowRollWeb.UserController do
  alias CowRoll.Schemas.Users.Auth
  use CowRollWeb, :controller
  import CowRollWeb.ErrorCodes

  @spec register_user(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def register_user(conn, _) do
    params = Auth.get_attributes(conn.body_params)
    # Aquí hay que devolver el id
    case Auth.register_user(params) do
      {:ok, id} ->
        json(conn, %{message: id})

      {:error, reason} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: reason})
    end
  end

  @spec login_user(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def login_user(conn, _) do
    reason = user_not_found()
    params = Auth.get_attributes(conn.body_params)

    case Auth.login_user(params) do
      {:ok, id} ->
        json(conn, %{message: id})

      {:error, ^reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: reason})

      {:error, reason} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: reason})
    end
  end
end
