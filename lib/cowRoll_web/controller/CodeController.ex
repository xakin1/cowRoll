defmodule CowRollWeb.CodeController do
  alias CowRoll.Interpreter
  import Interpreter
  import CowRoll.Parser
  use CowRollWeb, :controller
  require Logger

  def parse_code(conn, _) do
    code = conn.body_params["code"]

    try do
      json(conn, %{code: eval_input(code)})
    rescue
      e ->
        error_type = e.__struct__ |> Module.split() |> List.last()
        error_message = Exception.message(e)
        full_message = "#{error_type}: #{error_message}"
        json(conn, %{errorCode: full_message, line: e.line})
    end
  end

  def save_code(conn, _) do
    code = conn.body_params["code"]

    try do
      changeset = CowRoll.Code.changeset_new_user(%CowRoll.Code{}, %{code: code, user_id: 1})
      parse(code)

      case Mongo.insert_one(:mongo, "code", changeset.changes) do
        {:ok, _result} ->
          json(conn, %{message: "Code inserted successfully"})

        {:error, _} ->
          json(conn, %{error: "Failed to insert code"})
      end
    rescue
      e ->
        error_type = e.__struct__ |> Module.split() |> List.last()
        error_message = Exception.message(e)
        full_message = "#{error_type}: #{error_message}"
        changeset = CowRoll.Code.changeset_new_user(%CowRoll.Code{}, %{code: code, user_id: 1})

        case Mongo.insert_one(:mongo, "code", changeset.changes) do
          {:ok, _result} ->
            json(conn, %{
              message: "Code inserted successfully",
              errorCode: full_message,
              line: e.line
            })

          {:error, _} ->
            json(conn, %{error: "Failed to insert code", errorCode: full_message, line: e.line})
        end
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
        json(conn, %{errorCode: full_message, line: e.line})
    end
  end
end
