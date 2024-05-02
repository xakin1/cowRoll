defmodule CowRollWeb.CodeApiTest do
  use CowRollWeb.ConnCase, async: true
  use ExUnit.Case

  describe "POST /code" do
    test "evaluates code successfully", %{conn: conn} do
      conn = post(conn, "/api/code", code: "40+2")
      assert json_response(conn, 200)["output"] == 42
    end

    test "handles errors when code evaluation fails", %{conn: conn} do
      # This assumes eval_input will raise an error for this input
      conn = post(conn, "/api/code", code: "hola")

      assert json_response(conn, 200)["error"]["errorCode"] ==
               "RuntimeError: Variable 'hola' is not defined on line 1"

      assert json_response(conn, 200)["error"]["line"] == 1
    end
  end

  describe "POST /saveCode" do
    test "save code successfully", %{conn: conn} do
      conn = post(conn, "/api/saveCode", code: "40+2")
      assert json_response(conn, 200)["message"] == "Code inserted successfully"
    end

    test "code save fail", %{conn: conn} do
      conn = post(conn, "/api/saveCode", code: "40+'2'")
      assert conn.status == 200

      assert json_response(conn, 200)["error"]["errorCode"] ==
               "TypeError: Error at line 1 in '+' operation, Incompatible types: Integer, String were found but Integer, Integer were expected"

      assert json_response(conn, 200)["error"]["line"] == 1
    end
  end

  describe "POST /compile" do
    test "compile code successfully", %{conn: conn} do
      conn = post(conn, "/api/compile", code: "40+2")
      assert conn.status == 200
    end

    test "compile code fail", %{conn: conn} do
      conn = post(conn, "/api/compile", code: "40+'2'")
      assert conn.status == 200

      assert json_response(conn, 200)["error"]["errorCode"] ==
               "TypeError: Error at line 1 in '+' operation, Incompatible types: Integer, String were found but Integer, Integer were expected"

      assert json_response(conn, 200)["error"]["line"] == 1
    end
  end
end
