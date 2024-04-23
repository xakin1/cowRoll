defmodule CowRollWeb.CodeEval do
  alias CowRoll.Interpreter
  import Interpreter
  use CowRollWeb, :controller

  def parse_code(conn, _) do
    code = conn.body_params["code"]

    try do
      json(conn, %{code: eval_input(code)})
    rescue
      e ->
        error_type = e.__struct__ |> Module.split() |> List.last()
        error_message = Exception.message(e)
        full_message = "#{error_type}: #{error_message}"
        json(conn, %{error: full_message})
    end
  end
end
