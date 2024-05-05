defmodule CowRollWeb.CodeController do
  alias CowRoll.Interpreter
  import Interpreter
  import CowRoll.Parser
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

  def save_code(conn, %{"id" => user_id}) do
    user_id = String.to_integer(user_id)
    code = conn.body_params["content"]
    name = conn.body_params["name"]
    directory_name = conn.body_params["directoryName"]

    case find_or_create_directory(directory_name, user_id) do
      {:ok, directory_name} ->
        if name not in [nil, ""] do
          case find_or_create_code(name, user_id, code, directory_name.inserted_id) do
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
                    message: "Code inserted successfully",
                    error: %{
                      error: "Failed to insert code",
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

      {:error, reason} ->
        json(conn, %{error: reason})
    end
  end

  defp find_or_create_directory(name, user_id) do
    query = %{userId: user_id, name: name, type: "directory"}

    case Mongo.find_one(:mongo, "code", query) do
      nil ->
        changeset =
          CowRoll.Directory.changeset(
            %CowRoll.Directory{},
            %{userId: user_id, name: name, type: "directory"}
          )

        Mongo.insert_one(:mongo, "code", changeset.changes)

      directory ->
        directory
    end
  end

  defp find_or_create_code(name, user_id, code, directory_id) do
    query = %{
      userId: user_id,
      name: name,
      directory_id: directory_id
    }

    changeset =
      CowRoll.File.changeset(%CowRoll.File{}, %{
        name: name,
        content: code,
        userId: user_id,
        directory_id: directory_id
      })

    case Mongo.find_one(:mongo, "code", query) do
      nil ->
        Mongo.insert_one(:mongo, "code", changeset.changes)

      %{"_id" => existing_id} ->
        Mongo.update_one(:mongo, "code", %{_id: existing_id}, %{"$set" => %{content: code}})
    end
  end

  def compile_code(conn, _) do
    try do
      code = conn.body_params["code"]

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
    try do
      case Integer.parse(user_id) do
        :error ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: "Invalid user ID"})

        {user_id_int, _} ->
          cursor = Mongo.find(:mongo, "code", %{userId: user_id_int})

          codes =
            Enum.map(Enum.to_list(cursor), fn doc ->
              %{
                content: Map.get(doc, "content"),
                name: Map.get(doc, "name")
              }
            end)

          json(conn, %{data: codes})
      end
    rescue
      exception ->
        IO.inspect(exception)

        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Internal server error"})
    end
  end

  def rename_file(conn, %{"id" => user_id}) do
    user_id = String.to_integer(user_id)
    name = conn.body_params["name"]
    newName = conn.body_params["newName"]

    query = %{
      userId: user_id,
      name: name
    }

    case Mongo.find_one(:mongo, "code", query) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "File not found"})

      %{"_id" => existing_id} ->
        case Mongo.update_one(:mongo, "code", %{_id: existing_id}, %{
               "$set" => %{name: newName}
             }) do
          {:ok, _result} ->
            json(conn, %{message: "File name updated successfully"})

          {:error, _reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Failed to update file"})
        end
    end
  end
end
