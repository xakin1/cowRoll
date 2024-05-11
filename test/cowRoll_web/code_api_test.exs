defmodule CowRollWeb.CodeApiTest do
  use CowRollWeb.ConnCase, async: true
  use ExUnit.Case

  describe "POST /code" do
    test "evaluates code successfully", %{conn: conn} do
      conn = post(conn, "/api/code", content: "40+2")
      assert json_response(conn, 200)["message"] == 42
    end

    test "handles errors when code evaluation fails", %{conn: conn} do
      # This assumes eval_input will raise an error for this input
      conn = post(conn, "/api/code", content: "hola")

      assert json_response(conn, 200)["error"]["errorCode"] ==
               "RuntimeError: Variable 'hola' is not defined on line 1"

      assert json_response(conn, 200)["error"]["line"] == 1
    end
  end

  describe "POST /insertContent" do
    test "save code successfully", %{conn: conn} do
      conn = post(conn, "/api/createFile/1", name: "example")
      id = json_response(conn, 200)["message"]
      conn = post(conn, "/api/insertContent/1", content: "40+2", id: id)
      assert json_response(conn, 200)["message"] == "CONTENT_INSERTED"
    end

    test "code save fail", %{conn: conn} do
      conn = post(conn, "/api/createFile/1", name: "Example")
      id = json_response(conn, 200)["message"]

      conn = post(conn, "/api/insertContent/1", content: "40+'2'", id: id)
      assert conn.status == 200

      assert json_response(conn, 200)["error"]["errorCode"] ==
               "TypeError: Error at line 1 in '+' operation, Incompatible types: Integer, String were found but Integer, Integer were expected"

      assert json_response(conn, 200)["error"]["line"] == 1
    end

    test "code save fail beacause empty name", %{conn: conn} do
      conn = post(conn, "/api/insertContent/1", content: "40+'2'")
      assert conn.status == 200

      assert json_response(conn, 200)["error"] == "FILE_NOT_FOUND"
    end
  end

  describe "POST /compile" do
    test "compile code successfully", %{conn: conn} do
      conn = post(conn, "/api/compile", content: "40+2")
      assert conn.status == 200
    end

    test "compile empty code successfully", %{conn: conn} do
      conn = post(conn, "/api/compile", content: "")
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

  describe "POST /createDirectory" do
    test "create directory successfully", %{conn: conn} do
      conn = post(conn, "/api/createDirectory/1", name: "code")
      assert conn.status == 200

      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["message"] ==
               %{
                 "children" => [
                   %{
                     "children" => [],
                     "id" => 2,
                     "name" => "code",
                     "parentId" => 1,
                     "type" => "Directory"
                   }
                 ],
                 "id" => 1,
                 "name" => "Root",
                 "parentId" => nil,
                 "type" => "Directory"
               }
    end

    test "create directory with the same name", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory/1", name: "code")

      conn =
        post(conn, "/api/createDirectory/1", name: "code")

      assert json_response(conn, 200) == %{"error" => "DIRECTORY_NAME_ALREADY_EXISTS"}
    end

    test "create a subdirectory successfully", %{conn: conn} do
      conn = post(conn, "/api/createDirectory/1", name: "code")
      assert conn.status == 200

      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["message"] ==
               %{
                 "children" => [
                   %{
                     "children" => [],
                     "id" => 2,
                     "name" => "code",
                     "parentId" => 1,
                     "type" => "Directory"
                   }
                 ],
                 "id" => 1,
                 "name" => "Root",
                 "parentId" => nil,
                 "type" => "Directory"
               }

      conn = post(conn, "/api/createDirectory/1", name: "code2", parentId: 1)
      assert conn.status == 200

      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["message"] ==
               %{
                 "children" => [
                   %{
                     "children" => [],
                     "id" => 2,
                     "name" => "code",
                     "parentId" => 1,
                     "type" => "Directory"
                   },
                   %{
                     "children" => [],
                     "id" => 3,
                     "name" => "code2",
                     "parentId" => 1,
                     "type" => "Directory"
                   }
                 ],
                 "id" => 1,
                 "name" => "Root",
                 "parentId" => nil,
                 "type" => "Directory"
               }
    end
  end

  describe "POST /editContent" do
    setup %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory/1", name: "code")

      code1_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile/1",
          directoryId: code1_id,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent/1",
          id: id,
          content: "40+2"
        )

      assert conn.status == 200

      conn =
        post(conn, "/api/createDirectory/1", name: "code", parentId: code1_id)

      conn =
        post(conn, "/api/createFile/1",
          directoryId: code1_id,
          name: "example2"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent/1",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      conn =
        post(conn, "/api/createDirectory/1", name: "pj")

      pj_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile/1",
          directoryId: pj_id,
          name: "createPj"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent/1",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      conn =
        post(conn, "/api/createDirectory/1", name: "do_things", parentId: 6)

      do_things_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile/1",
          directoryId: do_things_id,
          name: "do_things"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent/1",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    test "edit file error", %{conn: conn} do
      conn =
        post(conn, "/api/createFile/1", name: "example")

      conn =
        post(conn, "/api/editFile/1", id: -1, content: "40+2", name: "example")

      assert conn.status == 404
    end

    test "move a directory", %{conn: conn} do
      conn =
        post(conn, "/api/editDirectory/1", id: 6, parentId: 1, name: "I change my name")

      assert conn.status == 200

      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["message"] ==
               %{
                 "children" => [
                   %{
                     "children" => [
                       %{
                         "content" => "40+2",
                         "directoryId" => 2,
                         "id" => 3,
                         "name" => "example",
                         "type" => "File"
                       },
                       %{
                         "content" => "'hola ' ++ 'mundo'",
                         "directoryId" => 2,
                         "id" => 5,
                         "name" => "example2",
                         "type" => "File"
                       },
                       %{
                         "children" => [],
                         "id" => 4,
                         "name" => "code",
                         "parentId" => 2,
                         "type" => "Directory"
                       }
                     ],
                     "id" => 2,
                     "name" => "code",
                     "parentId" => 1,
                     "type" => "Directory"
                   },
                   %{
                     "children" => [
                       %{
                         "content" => "'hola ' ++ 'mundo'",
                         "directoryId" => 6,
                         "id" => 7,
                         "name" => "createPj",
                         "type" => "File"
                       },
                       %{
                         "children" => [
                           %{
                             "content" => "'hola ' ++ 'mundo'",
                             "directoryId" => 8,
                             "id" => 9,
                             "name" => "do_things",
                             "type" => "File"
                           }
                         ],
                         "id" => 8,
                         "name" => "do_things",
                         "parentId" => 6,
                         "type" => "Directory"
                       }
                     ],
                     "id" => 6,
                     "name" => "I change my name",
                     "parentId" => 1,
                     "type" => "Directory"
                   }
                 ],
                 "id" => 1,
                 "name" => "Root",
                 "parentId" => nil,
                 "type" => "Directory"
               }
    end

    test "edit a file", %{conn: conn} do
      conn =
        post(conn, "/api/editFile/1",
          id: 7,
          directoryId: 8,
          name: "I change my name",
          content: "Im am a metamorph content"
        )

      assert conn.status == 200

      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["message"] ==
               %{
                 "children" => [
                   %{
                     "children" => [
                       %{
                         "content" => "40+2",
                         "directoryId" => 2,
                         "id" => 3,
                         "name" => "example",
                         "type" => "File"
                       },
                       %{
                         "content" => "'hola ' ++ 'mundo'",
                         "directoryId" => 2,
                         "id" => 5,
                         "name" => "example2",
                         "type" => "File"
                       },
                       %{
                         "children" => [],
                         "id" => 4,
                         "name" => "code",
                         "parentId" => 2,
                         "type" => "Directory"
                       }
                     ],
                     "id" => 2,
                     "name" => "code",
                     "parentId" => 1,
                     "type" => "Directory"
                   },
                   %{
                     "children" => [
                       %{
                         "children" => [
                           %{
                             "content" => "Im am a metamorph content",
                             "directoryId" => 8,
                             "id" => 7,
                             "name" => "I change my name",
                             "type" => "File"
                           },
                           %{
                             "content" => "'hola ' ++ 'mundo'",
                             "directoryId" => 8,
                             "id" => 9,
                             "name" => "do_things",
                             "type" => "File"
                           }
                         ],
                         "id" => 8,
                         "name" => "do_things",
                         "parentId" => 6,
                         "type" => "Directory"
                       }
                     ],
                     "id" => 6,
                     "name" => "pj",
                     "parentId" => 1,
                     "type" => "Directory"
                   }
                 ],
                 "id" => 1,
                 "name" => "Root",
                 "parentId" => nil,
                 "type" => "Directory"
               }
    end

    test "edit a non existing file", %{conn: conn} do
      conn =
        post(conn, "/api/editFile/1",
          id: 15,
          directoryId: 1,
          name: "I change my name",
          content: "Im am a metamorph content"
        )

      assert conn.status == 404

      assert json_response(conn, 404)["error"] == "FILE_NOT_FOUND"
    end

    test "edit a non existing directory", %{conn: conn} do
      conn =
        post(conn, "/api/editDirectory/1", directoryId: 15, parentId: 2, name: "I change my name")

      assert conn.status == 404

      assert json_response(conn, 404)["error"] == "FILE_NOT_FOUND"
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

      assert json_response(conn, 200)["message"] == %{
               "children" => [
                 %{
                   "content" => "42+2",
                   "directoryId" => 1,
                   "id" => 3,
                   "name" => "example",
                   "type" => "File"
                 },
                 %{
                   "content" => "40+2",
                   "directoryId" => 1,
                   "id" => 5,
                   "name" => "example",
                   "type" => "File"
                 }
               ],
               "id" => 1,
               "name" => "Root",
               "parentId" => nil,
               "type" => "Directory"
             }
    end

    test "get documments succesfully", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory/1", name: "code")

      conn =
        post(conn, "/api/insertContent/1", directoryId: 1, content: "40+2", name: "example")

      assert conn.status == 200
      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["message"] ==
               %{
                 "children" => [
                   %{
                     "children" => [
                       %{
                         "content" => "40+2",
                         "directoryId" => 1,
                         "id" => 4,
                         "name" => "example",
                         "type" => "File"
                       }
                     ],
                     "id" => 1,
                     "name" => "code",
                     "parentId" => 2,
                     "type" => "Directory"
                   }
                 ],
                 "id" => 2,
                 "name" => "Root",
                 "parentId" => nil,
                 "type" => "Directory"
               }
    end

    test "get 0 documments", %{conn: conn} do
      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["message"] == %{
               "children" => [],
               "id" => 1,
               "name" => "Root",
               "parentId" => nil,
               "type" => "Directory"
             }
    end

    test "creating a complex fileSystem", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory/1", name: "code")

      conn =
        post(conn, "/api/createFile/1",
          directoryId: 1,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent/1",
          id: id,
          content: "40+2"
        )

      assert conn.status == 200

      conn =
        post(conn, "/api/createDirectory/1", name: "code", parentId: 1)

      conn =
        post(conn, "/api/createFile/1",
          directoryId: 4,
          name: "example2"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent/1",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      conn =
        post(conn, "/api/createDirectory/1", name: "pj")

      conn =
        post(conn, "/api/createFile/1",
          directoryId: 6,
          name: "createPj"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent/1",
          id: id,
          name: "createPj"
        )

      conn =
        post(conn, "/api/createDirectory/1", name: "do_things", parentId: 6)

      conn =
        post(conn, "/api/createFile/1",
          directoryId: 8,
          name: "do_things"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent/1",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      assert conn.status == 200

      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["message"] ==
               %{
                 "children" => [
                   %{
                     "children" => [
                       %{
                         "content" => "40+2",
                         "directoryId" => 1,
                         "id" => 3,
                         "name" => "example",
                         "type" => "File"
                       },
                       %{
                         "children" => [
                           %{
                             "content" => "'hola ' ++ 'mundo'",
                             "directoryId" => 4,
                             "id" => 5,
                             "name" => "example2",
                             "type" => "File"
                           }
                         ],
                         "id" => 4,
                         "name" => "code",
                         "parentId" => 1,
                         "type" => "Directory"
                       }
                     ],
                     "id" => 1,
                     "name" => "code",
                     "parentId" => 2,
                     "type" => "Directory"
                   },
                   %{
                     "children" => [
                       %{
                         "content" => nil,
                         "directoryId" => 6,
                         "id" => 7,
                         "name" => "createPj",
                         "type" => "File"
                       },
                       %{
                         "children" => [
                           %{
                             "content" => "'hola ' ++ 'mundo'",
                             "directoryId" => 8,
                             "id" => 9,
                             "name" => "do_things",
                             "type" => "File"
                           }
                         ],
                         "id" => 8,
                         "name" => "do_things",
                         "parentId" => 6,
                         "type" => "Directory"
                       }
                     ],
                     "id" => 6,
                     "name" => "pj",
                     "parentId" => 2,
                     "type" => "Directory"
                   }
                 ],
                 "id" => 2,
                 "name" => "Root",
                 "parentId" => nil,
                 "type" => "Directory"
               }
    end
  end

  describe "POST /createFiles" do
    test "create file", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory/1", name: "code")

      conn =
        post(conn, "/api/createFile/1",
          directoryId: 1,
          name: "example"
        )

      assert conn.status == 200
      assert json_response(conn, 200) == %{"message" => 3}
    end

    test "create file with the same name", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory/1", name: "code")

      conn =
        post(conn, "/api/createFile/1",
          directoryId: 1,
          name: "example"
        )

      conn =
        post(conn, "/api/createFile/1",
          directoryId: 1,
          name: "example"
        )

      assert json_response(conn, 200) == %{"error" => "FILE_NAME_ALREADY_EXISTS"}
    end

    test "insert content", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory/1", name: "code")

      conn =
        post(conn, "/api/createFile/1",
          directoryId: 1,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent/1",
          id: 1,
          content: "40+2"
        )

      assert conn.status == 200
    end
  end

  describe "GET /filesById" do
    test "try get a not existing file", %{conn: conn} do
      conn = get(conn, "/api/file/1/1")
      assert conn.status == 404
    end

    test "try get an existing file", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory/1", name: "code")

      conn =
        post(conn, "/api/createFile/1",
          directoryId: 1,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent/1",
          id: id,
          content: "40+2"
        )

      conn = get(conn, "/api/file/1/#{id}")
      assert conn.status == 200

      assert json_response(conn, 200)["message"] == %{
               "content" => "40+2",
               "directoryId" => 1,
               "id" => 3,
               "name" => "example"
             }
    end
  end

  describe "DELETE /deleteFile" do
    test "delete a non existing file", %{conn: conn} do
      conn = delete(conn, "/api/deleteFile/1/-1")
      assert conn.status == 204
    end

    test "delete a existing file", %{conn: conn} do
      conn =
        post(conn, "/api/createFile/1", name: "example")

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent/1",
          content: "40+2",
          id: id
        )

      conn = delete(conn, "/api/deleteFile/1/#{id}")
      assert conn.status == 200
      assert json_response(conn, 200)["message"] == "FILE_DELETED"
    end

    test "delete a non existing directory", %{conn: conn} do
      conn = delete(conn, "/api/deleteDirectory/1/1")
      assert conn.status == 204
    end

    test "delete a existing directory without files", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory/1", name: "code")

      conn = delete(conn, "/api/deleteDirectory/1/1")
      assert conn.status == 200
      assert json_response(conn, 200)["message"] == "DIRECTORY_DELETED"
    end

    test "delete a existing directory with files", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory/1", name: "code")

      conn =
        post(conn, "/api/createFile/1",
          directoryId: 1,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent/1",
          id: id,
          content: "40+2"
        )

      conn =
        post(conn, "/api/createFile/1",
          directoryId: 1,
          name: "example2"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent/1",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      conn = delete(conn, "/api/deleteDirectory/1/1")
      assert conn.status == 200
      assert json_response(conn, 200)["message"] == "DIRECTORY_DELETED"

      conn = get(conn, "/api/file/1")

      assert json_response(conn, 200)["message"] == %{
               "children" => [],
               "id" => 2,
               "name" => "Root",
               "parentId" => nil,
               "type" => "Directory"
             }

      conn = get(conn, "/api/file/1/#{id}")
      assert conn.status == 404
    end
  end
end
