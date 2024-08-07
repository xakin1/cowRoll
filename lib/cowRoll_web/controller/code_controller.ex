defmodule CowRollWeb.CodeController do
  alias CowRoll.Interpreter
  import Interpreter
  import CowRoll.Parser

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

        line_number = Map.get(e, :line, 0)

        full_message = "#{error_type}: #{error_message}"

        json(conn, %{error: %{error: "", errorCode: full_message, line: line_number}})
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
end
