defmodule CowRollWeb.DirectoryController do
  import CowRoll.Directory
  import CowRollWeb.ErrorCodes
  import CowRollWeb.SuccesCodes
  import CowRollWeb.Controller.HelpersControllers
  use CowRollWeb, :controller
  require Logger

  def init(opts) do
    opts
  end

  def create_directory(conn, _) do
    user_id = get_user_id(conn)
    params = CowRoll.Directory.get_base_attributes(conn.body_params)

    case CowRoll.Directory.base_create_directory(user_id, params) do
      {:ok, directory_id} ->
        json(conn, %{message: directory_id})

      {:error, reason} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: reason})
    end
  end

  def get_files(conn, _) do
    user_id = get_user_id(conn)
    tree = get_directory_structure(user_id)

    json(conn, %{message: tree})
  end

  def edit_directory(conn, _) do
    user_id = get_user_id(conn)
    IO.puts(user_id)
    attributes = CowRoll.Directory.get_base_attributes(conn.body_params)
    reason = directory_not_found()

    case update_directory(user_id, attributes) do
      {:ok, _result} ->
        json(conn, %{message: directory_deleted()})

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

  def remove_directory(conn, %{"directoryId" => directory_id}) do
    user_id = get_user_id(conn)

    deleted_count = delete_directory(user_id, directory_id)

    if deleted_count > 0 do
      json(conn, %{message: directory_deleted()})
    else
      resp(conn, 204, "")
    end
  end

  @spec delete_all(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def delete_all(conn, _) do
    collections = ["file_system", "users"]
    Enum.map(collections, fn collection -> Mongo.delete_many(:mongo, collection, %{}) end)

    resp(conn, 200, "")
  end
end
