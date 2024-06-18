defmodule CowRollWeb.Plug.Authenticate do
  import Plug.Conn
  require Logger
  alias CowRoll.Token
  alias CowRoll.Schemas.Users.Users

  def init(opts), do: opts

  def call(conn, _opts) do
    token =
      case {conn.cookies["token"], get_req_header(conn, "authorization")} do
        {token, _} when is_binary(token) -> token
        {_, ["Bearer " <> token]} -> token
        _ -> nil
      end

    case token do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.put_view(CowRollWeb.ErrorJSON)
        |> Phoenix.Controller.render("401.json")
        |> halt()

      token ->
        case Token.verify(token) do
          {:ok, data} ->
            assign(conn, :current_user, Users.get_user_by_id(data["user_id"]))

          {:error, _reason} ->
            conn
            |> put_status(:unauthorized)
            |> Phoenix.Controller.put_view(CowRollWeb.ErrorJSON)
            |> Phoenix.Controller.render("401.json")
            |> halt()
        end
    end
  end
end
