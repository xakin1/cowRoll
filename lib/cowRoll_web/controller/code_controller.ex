defmodule CowRollWeb.CodeController do
  alias CowRoll.Interpreter
  import Interpreter
  import CowRoll.Parser
  import CowRoll.Directory
  import CowRoll.File
  import CowRollWeb.ErrorCodes
  import CowRollWeb.SuccesCodes
  use CowRollWeb, :controller
  require Logger

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

  def create_directory(conn, %{"id" => user_id}) do
    user_id = parse_id(user_id, conn)
    params = CowRoll.Directory.get_attributes(conn.body_params)

    case CowRoll.Directory.create_directory(user_id, params) do
      {:ok, directory_id} ->
        json(conn, %{message: directory_id})

      {:error, reason} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: reason})
    end
  end

  def create_file(conn, %{"id" => user_id}) do
    user_id = parse_id(user_id, conn)

    params = CowRoll.File.get_attributes(conn.body_params)
    params = set_parent_id(params, get_directory_id(params))

    case find_directory(user_id, params) do
      {:ok, directory_id} ->
        params = update_directory_id(params, directory_id)

        case CowRoll.File.create_file(user_id, params) do
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

  def insert_content(conn, %{"id" => user_id}) do
    user_id = parse_id(user_id, conn)

    params = CowRoll.File.get_attributes(conn.body_params)

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

  def get_files(conn, %{"id" => user_id}) do
    user_id = parse_id(user_id, conn)
    tree = get_directory_structure(user_id)

    json(conn, %{message: tree})
  end

  @spec get_file_by_id(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get_file_by_id(conn, %{"id" => user_id, "fileId" => file_id}) do
    user_id = parse_id(user_id, conn)

    file = get_file(user_id, file_id)

    if file == %{} do
      conn
      |> put_status(:not_found)
      |> json(%{error: empty_folder_name()})
    else
      json(conn, %{message: file})
    end
  end

  def edit_file(conn, %{"id" => user_id}) do
    user_id = parse_id(user_id, conn)

    attributes = CowRoll.File.get_attributes(conn.body_params)

    case update_file(user_id, attributes) do
      {:ok, _result} ->
        json(conn, %{message: file_updated()})

      {:error, reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: reason})
    end
  end

  def remove_file(conn, %{"id" => user_id, "fileId" => file_id}) do
    user_id = parse_id(user_id, conn)

    deleted_count = delete_file(user_id, file_id)

    if deleted_count > 0 do
      json(conn, %{message: file_deleted()})
    else
      resp(conn, 204, "")
    end
  end

  def edit_directory(conn, %{"id" => user_id}) do
    user_id = parse_id(user_id, conn)
    attributes = CowRoll.Directory.get_attributes(conn.body_params)
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

  def remove_directory(conn, %{"id" => user_id, "directoryId" => directory_id}) do
    user_id = parse_id(user_id, conn)

    deleted_count = delete_directory(user_id, directory_id)

    if deleted_count > 0 do
      json(conn, %{message: directory_deleted()})
    else
      resp(conn, 204, "")
    end
  end

  defp parse_id(id, conn) do
    case Integer.parse(id) do
      {id, ""} ->
        id

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: invalid_user_id()})
    end
  end

  def delete_all(_, _) do
    Mongo.delete_many(:mongo, "code", %{})
  end
end
