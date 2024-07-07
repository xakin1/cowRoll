defmodule CowRollWeb.CodeController do
  alias CowRoll.Interpreter
  import Interpreter
  import CowRoll.Parser
  import CowRoll.Code
  import CowRoll.Directory
  import CowRollWeb.ErrorCodes
  import CowRollWeb.SuccesCodes
  import CowRollWeb.Controller.HelpersControllers
  use CowRollWeb, :controller
  require Logger

  def init(opts) do
    opts
  end

  @spec run_code(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def run_code(conn, _) do
    code = conn.body_params["content"]

    try do
      json(conn, %{message: eval_input(code)})
    rescue
      e ->
        error_type = e.__struct__ |> Module.split() |> List.last()
        error_message = Exception.message(e)
        full_message = "#{error_type}: #{error_message}"
        json(conn, %{error: %{error: "", errorCode: full_message, line: e.line}})
    end
  end

  def create_file(conn, _) do
    user_id = get_user_id(conn)

    params = CowRoll.Code.get_attributes(conn.body_params)
    params = set_parent_id(params, get_directory_id(params))

    case find_directory(user_id, params) do
      {:ok, directory_id} ->
        params = update_directory_id(params, directory_id)

        case CowRoll.Code.create_file(user_id, params) do
          {:ok, file_id} ->
            json(conn, %{message: file_id})

          {:error, reason} ->
            conn
            |> put_status(:forbidden)
            |> json(%{error: reason})
        end

      {:error, reason} ->
        conn |> put_status(:not_found) |> json(%{error: reason})
    end
  end

  def insert_content(conn, _) do
    user_id = get_user_id(conn)

    params = CowRoll.Code.get_attributes(conn.body_params)

    case update_file(user_id, params) do
      {:error, error} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: error})

      _ ->
        case compile(get_content(params)) do
          :ok -> json(conn, %{message: content_inserted()})
          {:error, error} -> json(conn, %{message: content_inserted(), error: error})
        end
    end
  end

  def compile_code(conn, _) do
    code = conn.body_params["content"]

    case compile(code) do
      :ok ->
        json(conn, "")

      {:error, error} ->
        json(conn, %{error: error})
    end
  end

  defp compile(content) do
    try do
      if content != nil and content != "", do: parse(content)
      :ok
    rescue
      e ->
        error_type = e.__struct__ |> Module.split() |> List.last()
        error_message = Exception.message(e)
        full_message = "#{error_type}: #{error_message}"
        {:error, %{error: "", errorCode: full_message, line: e.line}}
    end
  end

  def get_files(conn, _) do
    user_id = get_user_id(conn)
    tree = get_directory_structure(user_id)

    json(conn, %{message: tree})
  end

  @spec get_file_by_id(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get_file_by_id(conn, %{"fileId" => file_id}) do
    user_id = get_user_id(conn)

    file = get_file(user_id, file_id)

    if file == %{} do
      conn
      |> put_status(:not_found)
      |> json(%{error: empty_folder_name()})
    else
      json(conn, %{message: file})
    end
  end

  def edit_file(conn, _) do
    user_id = get_user_id(conn)

    attributes = CowRoll.Code.get_attributes(conn.body_params)

    case update_file(user_id, attributes) do
      {:ok, _result} ->
        json(conn, %{message: file_updated()})

      {:error, reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: reason})
    end
  end

  def remove_file(conn, %{"fileId" => file_id}) do
    user_id = get_user_id(conn)

    deleted_count = delete_file(user_id, file_id)

    if deleted_count > 0 do
      json(conn, %{message: file_deleted()})
    else
      resp(conn, 204, "")
    end
  end

  def delete_all(conn, _) do
    collections = ["code", "users"]
    Enum.map(collections, fn collection -> Mongo.delete_many(:mongo, collection, %{}) end)

    resp(conn, 200, "")
  end
end
