defmodule CowRollWeb.CodeController do
  alias CowRoll.Interpreter
  import Interpreter
  import CowRoll.Parser
  use CowRollWeb, :controller
  require Logger

  def run_code(conn, _) do
    code = conn.body_params["code"]

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
    code = conn.body_params["code"]
    name = conn.body_params["fileName"]

    if name not in [nil, ""] do
      case find_or_create_code(name, user_id, code) do
        {:ok, _result} ->
          json(conn, %{message: "Code saved successfully"})

        {:error, reason} ->
          json(conn, %{error: reason})
      end
    else
      json(conn, %{
        error: "File name can't be empty"
      })
    end
  end

  defp find_or_create_code(name, user_id, code) do
    query = %{
      userId: user_id,
      fileName: name
    }

    changeset =
      CowRoll.Code.changeset_new_file(%CowRoll.Code{}, %{
        fileName: name,
        code: code,
        userId: user_id
      })

    case Mongo.find_one(:mongo, "code", query) do
      nil ->
        Mongo.insert_one(:mongo, "code", changeset.changes)

      %{"_id" => existing_id} ->
        Mongo.update_one(:mongo, "code", %{_id: existing_id}, %{"$set" => %{code: code}})
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
                code: Map.get(doc, "code"),
                fileName: Map.get(doc, "fileName")
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
end
