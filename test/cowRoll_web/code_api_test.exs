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
      conn = post(conn, "/api/insertContent/1", content: "40+2", name: "example")
      assert json_response(conn, 200)["message"] == "Code saved successfully"
    end

    test "code save fail", %{conn: conn} do
      conn = post(conn, "/api/insertContent/1", content: "40+'2'", name: "Example")
      assert conn.status == 200

      assert json_response(conn, 200)["error"]["errorCode"] ==
               "TypeError: Error at line 1 in '+' operation, Incompatible types: Integer, String were found but Integer, Integer were expected"

      assert json_response(conn, 200)["error"]["line"] == 1
    end

    test "code save fail beacause empty name", %{conn: conn} do
      conn = post(conn, "/api/insertContent/1", content: "40+'2'")
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

  describe "POST /editContent" do
    setup %{conn: conn} do
      conn =
        post(conn, "/api/insertContent/1",
          directory: "code",
          content: "40+2",
          name: "example"
        )

      conn =
        post(conn, "/api/insertContent/1",
          directory: "code",
          parentId: 2,
          content: "'hola ' ++ 'mundo'",
          name: "example2"
        )

      conn =
        post(conn, "/api/insertContent/1",
          directory: "pj",
          content: "'hola ' ++ 'mundo'",
          name: "createPj"
        )

      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    test "get files error", %{conn: conn} do
      conn =
        post(conn, "/api/editContent/1", content: "40+2", name: "example", newName: "example2")

      assert conn.status == 404
    end

    test "move a directory", %{conn: conn} do
      conn =
        post(conn, "/api/editDirectory/1", directoryId: 5, parentId: 2, name: "I change my name")

      assert conn.status == 200

      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["data"] ==
               %{
                 "children" => [
                   %{
                     "children" => [
                       %{
                         "content" => "40+2",
                         "id" => 3,
                         "name" => "example",
                         "type" => "File"
                       },
                       %{
                         "content" => "'hola ' ++ 'mundo'",
                         "id" => 4,
                         "name" => "example2",
                         "type" => "File"
                       },
                       %{
                         "children" => [
                           %{
                             "content" => "'hola ' ++ 'mundo'",
                             "id" => 6,
                             "name" => "createPj",
                             "type" => "File"
                           }
                         ],
                         "id" => 5,
                         "name" => "I change my name",
                         "type" => "Directory"
                       }
                     ],
                     "id" => 2,
                     "name" => "code",
                     "type" => "Directory"
                   }
                 ],
                 "id" => 1,
                 "name" => "Root",
                 "type" => "Directory"
               }
    end

    test "edit a file", %{conn: conn} do
      conn =
        post(conn, "/api/editFile/1",
          fileId: 6,
          directoryId: 1,
          name: "I change my name",
          content: "Im am a metamorph content"
        )

      assert conn.status == 200

      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["data"] ==
               %{
                 "children" => [
                   %{
                     "content" => "Im am a metamorph content",
                     "id" => 6,
                     "name" => "I change my name",
                     "type" => "File"
                   },
                   %{
                     "children" => [
                       %{
                         "content" => "40+2",
                         "id" => 3,
                         "name" => "example",
                         "type" => "File"
                       },
                       %{
                         "content" => "'hola ' ++ 'mundo'",
                         "id" => 4,
                         "name" => "example2",
                         "type" => "File"
                       }
                     ],
                     "id" => 2,
                     "name" => "code",
                     "type" => "Directory"
                   },
                   %{
                     "children" => [],
                     "id" => 5,
                     "name" => "pj",
                     "type" => "Directory"
                   }
                 ],
                 "id" => 1,
                 "name" => "Root",
                 "type" => "Directory"
               }
    end

    test "edit a non existing file", %{conn: conn} do
      conn =
        post(conn, "/api/editFile/1",
          fileId: 15,
          directoryId: 1,
          name: "I change my name",
          content: "Im am a metamorph content"
        )

      assert conn.status == 404

      assert json_response(conn, 404)["error"] == "File not found"
    end

    test "edit a non existing directory", %{conn: conn} do
      conn =
        post(conn, "/api/editDirectory/1", directoryId: 15, parentId: 2, name: "I change my name")

      assert conn.status == 404

      assert json_response(conn, 404)["error"] == "File not found"
    end
  end

  describe "GET /files" do
    test "get files succesfully", %{conn: conn} do
      conn = get(conn, "/api/file/1", content: "40+2", name: "example")
      assert conn.status == 200
    end

    test "get overwrite documments", %{conn: conn} do
      conn = post(conn, "/api/insertContent/1", content: "42+2", name: "example")
      assert conn.status == 200
      conn = post(conn, "/api/insertContent/1", content: "40+2", name: "example")
      assert conn.status == 200
      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["data"] == %{
               "children" => [
                 %{
                   "content" => "40+2",
                   "id" => 2,
                   "name" => "example",
                   "type" => "File"
                 }
               ],
               "id" => 1,
               "name" => "Root",
               "type" => "Directory"
             }
    end

    test "get documments succesfully", %{conn: conn} do
      conn =
        post(conn, "/api/insertContent/1", directory: "code", content: "40+2", name: "example")

      assert conn.status == 200
      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["data"] ==
               %{
                 "children" => [
                   %{
                     "children" => [
                       %{
                         "content" => "40+2",
                         "id" => 3,
                         "name" => "example",
                         "type" => "File"
                       }
                     ],
                     "id" => 2,
                     "name" => "code",
                     "type" => "Directory"
                   }
                 ],
                 "id" => 1,
                 "name" => "Root",
                 "type" => "Directory"
               }
    end

    test "get 0 documments", %{conn: conn} do
      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["data"] == %{
               "children" => [],
               "id" => 1,
               "name" => "Root",
               "type" => "Directory"
             }
    end

    test "creating a complex fileSystem", %{conn: conn} do
      conn =
        post(conn, "/api/insertContent/1",
          directory: "code",
          content: "40+2",
          name: "example"
        )

      assert conn.status == 200

      conn =
        post(conn, "/api/insertContent/1",
          directory: "code",
          parentId: 2,
          content: "'hola ' ++ 'mundo'",
          name: "example2"
        )

      conn =
        post(conn, "/api/insertContent/1",
          directory: "pj",
          content: "'hola ' ++ 'mundo'",
          name: "createPj"
        )

      conn =
        post(conn, "/api/insertContent/1",
          directory: "do_things",
          parentId: 5,
          content: "'hola ' ++ 'mundo'",
          name: "do_things"
        )

      assert conn.status == 200

      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["data"] ==
               %{
                 "children" => [
                   %{
                     "children" => [
                       %{
                         "content" => "40+2",
                         "id" => 3,
                         "name" => "example",
                         "type" => "File"
                       },
                       %{
                         "content" => "'hola ' ++ 'mundo'",
                         "id" => 4,
                         "name" => "example2",
                         "type" => "File"
                       }
                     ],
                     "id" => 2,
                     "name" => "code",
                     "type" => "Directory"
                   },
                   %{
                     "children" => [
                       %{
                         "content" => "'hola ' ++ 'mundo'",
                         "id" => 6,
                         "name" => "createPj",
                         "type" => "File"
                       },
                       %{
                         "children" => [
                           %{
                             "content" => "'hola ' ++ 'mundo'",
                             "id" => 8,
                             "name" => "do_things",
                             "type" => "File"
                           }
                         ],
                         "id" => 7,
                         "name" => "do_things",
                         "type" => "Directory"
                       }
                     ],
                     "id" => 5,
                     "name" => "pj",
                     "type" => "Directory"
                   }
                 ],
                 "id" => 1,
                 "name" => "Root",
                 "type" => "Directory"
               }
    end

    test "create a folder", %{conn: conn} do
      conn =
        post(conn, "/api/insertContent/1", directory: "code")

      assert conn.status == 200

      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["data"] ==
               %{
                 "children" => [
                   %{
                     "children" => [],
                     "id" => 2,
                     "name" => "code",
                     "type" => "Directory"
                   }
                 ],
                 "id" => 1,
                 "name" => "Root",
                 "type" => "Directory"
               }
    end
  end
end
