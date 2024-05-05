defmodule CowRollWeb.CodeApiTest do
  use CowRollWeb.ConnCase, async: true
  use ExUnit.Case

  describe "POST /code" do
    test "evaluates code successfully", %{conn: conn} do
      conn = post(conn, "/api/code", content: "40+2")
      assert json_response(conn, 200)["output"] == 42
    end

    test "handles errors when code evaluation fails", %{conn: conn} do
      # This assumes eval_input will raise an error for this input
      conn = post(conn, "/api/code", content: "hola")

      assert json_response(conn, 200)["error"]["errorCode"] ==
               "RuntimeError: Variable 'hola' is not defined on line 1"

      assert json_response(conn, 200)["error"]["line"] == 1
    end
  end

  describe "POST /saveCode" do
    test "save code successfully", %{conn: conn} do
      conn = post(conn, "/api/saveCode/1", content: "40+2", name: "example")
      assert json_response(conn, 200)["message"] == "Code saved successfully"
    end

    test "code save fail", %{conn: conn} do
      conn = post(conn, "/api/saveCode/1", content: "40+'2'", name: "Example")
      assert conn.status == 200

      assert json_response(conn, 200)["error"]["errorCode"] ==
               "TypeError: Error at line 1 in '+' operation, Incompatible types: Integer, String were found but Integer, Integer were expected"

      assert json_response(conn, 200)["error"]["line"] == 1
    end

    test "code save fail beacause empty name", %{conn: conn} do
      conn = post(conn, "/api/saveCode/1", content: "40+'2'")
      assert conn.status == 200

      assert json_response(conn, 200)["error"] ==
               "File name can't be empty"
    end
  end

  describe "POST /compile" do
    test "compile code successfully", %{conn: conn} do
      conn = post(conn, "/api/compile", content: "40+2")
      assert conn.status == 200
    end

    test "compile code fail", %{conn: conn} do
      conn = post(conn, "/api/compile", content: "40+'2'")
      assert conn.status == 200

      assert json_response(conn, 200)["error"]["errorCode"] ==
               "TypeError: Error at line 1 in '+' operation, Incompatible types: Integer, String were found but Integer, Integer were expected"

      assert json_response(conn, 200)["error"]["line"] == 1
    end
  end

  describe "POST /renameFile" do
    test "get files error", %{conn: conn} do
      conn =
        post(conn, "/api/renameFile/1", content: "40+2", name: "example", newName: "example2")

      assert conn.status == 404
    end

    test "get files success", %{conn: conn} do
      name = "example"
      conn = post(conn, "/api/saveCode/1", content: "40+2", name: name)
      assert conn.status == 200

      conn =
        post(conn, "/api/renameFile/1", name: name, newName: "example2")

      assert conn.status == 200
    end
  end

  describe "GET /files" do
    test "get files succesfully", %{conn: conn} do
      conn = get(conn, "/api/file/1", content: "40+2", name: "example")
      assert conn.status == 200
    end

    test "get overwrite documments", %{conn: conn} do
      conn = post(conn, "/api/saveCode/1", content: "42+2", name: "example")
      assert conn.status == 200
      conn = post(conn, "/api/saveCode/1", content: "40+2", name: "example")
      assert conn.status == 200
      conn = get(conn, "/api/file/1")
      assert json_response(conn, 200)["data"] == [%{"content" => "40+2", "name" => "example"}]
    end

    test "get documments succesfully", %{conn: conn} do
      conn = post(conn, "/api/saveCode/1", content: "40+2", name: "example")
      assert conn.status == 200
      conn = get(conn, "/api/file/1")
      assert json_response(conn, 200)["data"] == [%{"content" => "40+2", "name" => "example"}]
    end

    test "get 0 documments", %{conn: conn} do
      conn = get(conn, "/api/file/1")
      assert json_response(conn, 200)["data"] == []
    end

    test "create a folder", %{conn: conn} do
      conn =
        post(conn, "/api/saveCode/1", directoryName: "code")

      assert conn.status == 200
    end

    test "create a folder with code", %{conn: conn} do
      conn =
        post(conn, "/api/saveCode/1", content: "1+1", directoryName: "code")

      assert conn.status == 200
      assert json_response(conn, 200)["error"] == "File name can't be empty"
    end
  end
end
