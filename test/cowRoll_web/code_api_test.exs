defmodule CowRollWeb.CodeApiTest do
  alias CowRollWeb.CodeEval
  use CowRollWeb.ConnCase, async: true
  use ExUnit.Case

  describe "POST /code" do
    test "evaluates code successfully", %{conn: conn} do
      conn = post(conn, "/api/code", code: "40+2")
      assert json_response(conn, 200)["code"] == 42
    end

    test "handles errors when code evaluation fails", %{conn: conn} do
      # This assumes eval_input will raise an error for this input
      conn = post(conn, "/api/code", code: "hola")

      assert json_response(conn, 200)["error"] ==
               "RuntimeError: Variable 'hola' is not defined on line 1"
    end
  end
end
