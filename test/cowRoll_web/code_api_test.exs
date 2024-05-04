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
      conn = post(conn, "/api/saveCode/1", code: "40+2", fileName: "example")
      assert json_response(conn, 200)["message"] == "Code inserted successfully"
    end

    test "code save fail", %{conn: conn} do
      conn = post(conn, "/api/saveCode/1", code: "40+'2'", fileName: "Example")
      assert conn.status == 200

      assert json_response(conn, 200)["error"]["errorCode"] ==
               "TypeError: Error at line 1 in '+' operation, Incompatible types: Integer, String were found but Integer, Integer were expected"

      assert json_response(conn, 200)["error"]["line"] == 1
    end

    test "code save fail beacause empty name", %{conn: conn} do
      conn = post(conn, "/api/saveCode/1", code: "40+'2'")
      assert conn.status == 200

      assert json_response(conn, 200)["error"]["errorCode"] ==
               "File name cant be empty"

      assert json_response(conn, 200)["error"]["line"] == nil
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

  describe "GET /files" do
    test "get files succesfully", %{conn: conn} do
      conn = get(conn, "/api/file/1", code: "40+2", fileName: "example")
      assert conn.status == 200
    end

    test "get overwrite documments", %{conn: conn} do
      conn = post(conn, "/api/saveCode/1", code: "42+2", fileName: "example")
      assert conn.status == 200
      conn = post(conn, "/api/saveCode/1", code: "40+2", fileName: "example")
      assert conn.status == 200
      conn = get(conn, "/api/file/1")
      assert json_response(conn, 200)["data"] == [%{"code" => "40+2", "fileName" => "example"}]
    end

    test "get documments succesfully", %{conn: conn} do
      conn = post(conn, "/api/saveCode/1", code: "40+2", fileName: "example")
      assert conn.status == 200
      conn = get(conn, "/api/file/1")
      assert json_response(conn, 200)["data"] == [%{"code" => "40+2", "fileName" => "example"}]
    end

    test "get 0 documments", %{conn: conn} do
      conn = get(conn, "/api/file/1")
      assert json_response(conn, 200)["data"] == []
    end
  end
end
