defmodule CowRollWeb.UserController do
  import CowRollWeb.Controller.HelpersControllers
  import CowRollWeb.SuccesCodes
  alias CowRoll.Schemas.Users.Auth
  use CowRollWeb, :controller
  import CowRollWeb.ErrorCodes

  defp create_user_directory_system(params) do
    with {:ok, user_id} <- Auth.get_user_id(params),
         {:ok, roles_id} <- CowRoll.Directory.create_directory(user_id, %{name: "Roles"}),
         {:ok, _sheets_id} <-
           CowRoll.Directory.create_directory(user_id, %{name: "Sheets", parent_id: roles_id}),
         {:ok, _codes_id} <-
           CowRoll.Directory.create_directory(user_id, %{name: "Codes", parent_id: roles_id}) do
      :ok
    else
      {:error, error} -> {:error, error}
    end
  end

  @spec register_user(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def register_user(conn, _) do
    params = Auth.get_attributes(conn.body_params)
    # Aquí hay que devolver el id
    case Auth.register_user(params) do
      {:ok, token} ->
        case create_user_directory_system(params) do
          :ok ->
            conn
            |> put_resp_cookie("token", token, http_only: true, secure: false, same_site: "Lax")
            |> json(%{message: token})

          {:error, reason} ->
            conn
            |> put_status(:forbidden)
            |> json(%{error: reason})
        end

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
      {:ok, token} ->
        conn
        |> put_resp_cookie("token", token, http_only: true, secure: true, same_site: "Strict")
        |> json(%{message: token})

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

  def unregister_user(conn, _) do
    user_id = get_user_id(conn)

    case Auth.unregister_user(user_id) do
      :ok ->
        json(conn, %{message: user_deleted()})

      {:error, reason} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: reason})
    end
  end
end
