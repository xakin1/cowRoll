defmodule CowRollWeb.CodeController do
  alias CowRoll.Interpreter
  import Interpreter
  import CowRoll.Parser
  import CowRoll.Directory
  import CowRoll.File
  use CowRollWeb, :controller
  require Logger

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
    attributes = CowRoll.Directory.get_attributes(conn.body_params)

    case CowRoll.Directory.create_directory(user_id, attributes) do
      {:ok, directory_id} -> json(conn, %{message: directory_id})
      {:error, reason} -> json(conn, %{error: reason})
    end
  end

  def insert_content(conn, %{"id" => user_id}) do
    user_id = parse_id(user_id, conn)

    parent_directory_id = conn.body_params["directoryId"]
    params = CowRoll.File.get_attributes(conn.body_params)

    case find_directory(user_id, parent_directory_id) do
      {:ok, directory_id} ->
        params = update_directory_id(params, directory_id)
        insert_content(conn, user_id, params)

      {:error, reason} ->
        conn |> put_status(:not_found) |> json(%{error: reason})
    end
  end

  defp insert_content(conn, user_id, params) do
    case update_or_create_file(user_id, params) do
      {:ok, _result} ->
        try do
          parse(conn.body_params["content"])
          json(conn, %{message: "Content saved successfully"})
        rescue
          e ->
            error_type = e.__struct__ |> Module.split() |> List.last()
            error_message = Exception.message(e)
            full_message = "#{error_type}: #{error_message}"

            json(conn, %{
              message: "Content saved successfully",
              error: %{
                error: "Failed to compile code",
                errorCode: full_message,
                line: e.line
              }
            })
        end

      {:error, reason} ->
        json(conn, %{error: reason})
    end
  end

  def compile_code(conn, _) do
    try do
      code = conn.body_params["content"]

      parse(code)
      send_resp(conn, 200, "")
    rescue
      e ->
        error_type = e.__struct__ |> Module.split() |> List.last()
        error_message = Exception.message(e)
        full_message = "#{error_type}: #{error_message}"
        json(conn, %{error: %{error: "", errorCode: full_message, line: e.line}})
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
    file_id = parse_id(file_id, conn)
    file = get_file(user_id, file_id)

    if file == %{} do
      conn
      |> put_status(:not_found)
      |> json(%{error: "File not found"})
    else
      json(conn, %{message: file})
    end
  end

  def edit_file(conn, %{"id" => user_id}) do
    user_id = parse_id(user_id, conn)
    file_id = conn.body_params["id"]

    attributes = CowRoll.File.get_attributes(conn.body_params)

    case update_file(user_id, file_id, attributes) do
      {:ok, _result} ->
        json(conn, %{message: "File name updated successfully"})

      {:error, reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: reason})
    end
  end

  def remove_file(conn, %{"id" => user_id, "fileId" => file_id}) do
    user_id = parse_id(user_id, conn)
    file_id = parse_id(file_id, conn)

    deleted_count = delete_file(user_id, file_id)

    if deleted_count > 0 do
      json(conn, %{message: "File was deleted successfully"})
    else
      resp(conn, 204, "")
    end
  end

  def edit_directory(conn, %{"id" => user_id}) do
    user_id = parse_id(user_id, conn)
    directory_id = conn.body_params["id"]

    attributes = CowRoll.Directory.get_attributes(conn.body_params)

    case update_directory(user_id, directory_id, attributes) do
      {:ok, _result} ->
        json(conn, %{message: "Directory name updated successfully"})

      {:error, reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: reason})
    end
  end

  def remove_directory(conn, %{"id" => user_id, "directoryId" => directory_id}) do
    user_id = parse_id(user_id, conn)
    directory_id = parse_id(directory_id, conn)

    deleted_count = delete_directory(user_id, directory_id)

    if deleted_count > 0 do
      json(conn, %{message: "Directory was deleted successfully"})
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
        |> json(%{error: "Invalid user ID"})
    end
  end
end
