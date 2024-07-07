defmodule CowRollWeb.SheetController do
  import CowRoll.Directory
  import CowRoll.Sheet
  import CowRollWeb.ErrorCodes
  import CowRollWeb.SuccesCodes
  import CowRollWeb.Controller.HelpersControllers
  use CowRollWeb, :controller
  require Logger

  def init(opts) do
    opts
  end

  def create_sheet(conn, _) do
    user_id = get_user_id(conn)

    params = CowRoll.Sheet.get_attributes(conn.body_params)
    params = set_parent_id(params, get_directory_id(params))

    case find_directory(user_id, params) do
      {:ok, directory_id} ->
        params = update_directory_id(params, directory_id)

        case CowRoll.Sheet.create_file(user_id, params) do
          {:ok, sheet_id} ->
            json(conn, %{message: sheet_id})

          {:error, reason} ->
            conn
            |> put_status(:forbidden)
            |> json(%{error: reason})
        end

      {:error, reason} ->
        conn |> put_status(:not_found) |> json(%{error: reason})
    end
  end

  def save_sheet(conn, _) do
    user_id = get_user_id(conn)

    params = CowRoll.Sheet.get_attributes(conn.body_params)

    case update_file(user_id, params) do
      {:error, error} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: error})

      _ ->
        json(conn, %{message: content_inserted()})
    end
  end

  def get_sheets(conn, _) do
    user_id = get_user_id(conn)
    tree = get_directory_structure(user_id)

    json(conn, %{message: tree})
  end

  @spec get_sheet_by_id(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get_sheet_by_id(conn, %{"sheetId" => sheet_id}) do
    user_id = get_user_id(conn)

    file = get_file(user_id, sheet_id)

    if file == %{} do
      conn
      |> put_status(:not_found)
      |> json(%{error: empty_folder_name()})
    else
      json(conn, %{message: file})
    end
  end

  def edit_sheet(conn, _) do
    user_id = get_user_id(conn)

    attributes = CowRoll.Sheet.get_attributes(conn.body_params)

    case update_file(user_id, attributes) do
      {:ok, _result} ->
        json(conn, %{message: file_updated()})

      {:error, reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: reason})
    end
  end

  def remove_sheet(conn, %{"sheetId" => sheet_id}) do
    user_id = get_user_id(conn)

    deleted_count = delete_file(user_id, sheet_id)

    if deleted_count > 0 do
      json(conn, %{message: file_deleted()})
    else
      resp(conn, 204, "")
    end
  end

  def delete_all(conn, _) do
    collections = ["code", "users", "file_system"]
    Enum.map(collections, fn collection -> Mongo.delete_many(:mongo, collection, %{}) end)

    resp(conn, 200, "")
  end
end
