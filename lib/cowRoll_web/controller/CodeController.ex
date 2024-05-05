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
      json(conn, %{output: eval_input(code)})
    rescue
      e ->
        error_type = e.__struct__ |> Module.split() |> List.last()
        error_message = Exception.message(e)
        full_message = "#{error_type}: #{error_message}"
        json(conn, %{error: %{error: "", errorCode: full_message, line: e.line}})
    end
  end

  def insert_content(conn, %{"id" => user_id}) do
    user_id = parse_id(user_id, conn)
    content = conn.body_params["content"]
    name = conn.body_params["name"]
    directory_name = conn.body_params["directory"]
    parent_directory_id = conn.body_params["parentId"]

    case find_or_create_directory(user_id, directory_name, parent_directory_id) do
      {:ok, directory_id} -> insert_content(directory_id, name, user_id, content, conn)
      {:error, reason} -> conn |> put_status(:not_found) |> json(%{error: reason})
    end
  end

  defp insert_content(directory_id, name, user_id, code, conn) do
    if name not in [nil, ""] do
      case update_or_create_file(name, user_id, code, directory_id) do
        {:ok, _result} ->
          try do
            parse(code)
            json(conn, %{message: "Code saved successfully"})
          rescue
            e ->
              error_type = e.__struct__ |> Module.split() |> List.last()
              error_message = Exception.message(e)
              full_message = "#{error_type}: #{error_message}"

              json(conn, %{
                message: "Code saved successfully",
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
    else
      if(code in [nil, ""]) do
        json(conn, %{
          message: "Directory create was created succesfully"
        })
      else
        json(conn, %{
          error: "File name can't be empty"
        })
      end
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

    json(conn, %{data: tree})
  end

  def edit_file(conn, %{"id" => user_id}) do
    user_id = parse_id(user_id, conn)
    fileId = conn.body_params["fileId"]

    attributes = CowRoll.File.get_attributes(conn.body_params)

    case update_file(user_id, fileId, attributes) do
      {:ok, _result} ->
        json(conn, %{message: "File name updated successfully"})

      {:error, reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: reason})
    end
  end

  def edit_directory(conn, %{"id" => user_id}) do
    user_id = parse_id(user_id, conn)
    directoryId = conn.body_params["directoryId"]

    attributes = CowRoll.Directory.get_attributes(conn.body_params)

    case update_directory(user_id, directoryId, attributes) do
      {:ok, _result} ->
        json(conn, %{message: "Directory name updated successfully"})

      {:error, reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: reason})
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
