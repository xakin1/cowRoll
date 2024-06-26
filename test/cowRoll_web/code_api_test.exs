defmodule CowRollWeb.CodeApiTest do
  use CowRollWeb.ConnCase, async: true
  import CowRollWeb.ErrorCodes
  import CowRollWeb.SuccesCodes
  import CowRoll.Schemas.Users.Auth
  use ExUnit.Case

  # Bloque setup que solo se aplica a este módulo de pruebas
  setup %{conn: conn} do
    conn = post(conn, "/api/signUp", username: "sujeto1", password: "aAcs1234.")
    conn = post(conn, "/api/login", username: "sujeto1", password: "aAcs1234.")
    token = json_response(conn, 200)["message"]
    conn = build_conn() |> put_req_header("authorization", "Bearer #{token}")

    {:ok, conn: conn}
  end

  describe "POST /calls without permisson" do
    setup %{conn: conn} do
      conn = conn |> delete_req_header("authorization")
      {:ok, conn: conn}
    end

    test "/api/code without permission", %{conn: conn} do
      conn = post(conn, "/api/code", content: "40+2")
      assert conn.status == 401
    end

    test "/api/createFile without permission", %{conn: conn} do
      conn = post(conn, "/api/createFile", name: "example")
      assert conn.status == 401
    end

    test "/api/createDirectory without permission", %{conn: conn} do
      conn = post(conn, "/api/createDirectory", name: "example")
      assert conn.status == 401
    end

    test "/api/compile without permission", %{conn: conn} do
      conn = post(conn, "/api/compile", content: "40+2")
      assert conn.status == 401
    end

    test "/api/insertContent without permission", %{conn: conn} do
      conn = post(conn, "/api/insertContent", content: "40+2")
      assert conn.status == 401
    end

    test "/api/file without permission", %{conn: conn} do
      conn = conn = get(conn, "/api/file")
      assert conn.status == 401
    end

    test "/api/editFile without permission", %{conn: conn} do
      conn =
        post(conn, "/api/editFile", id: -1, content: "40+2", name: "example")

      assert conn.status == 401
    end

    test "/api/editDirectory without permission", %{conn: conn} do
      conn =
        post(conn, "/api/editDirectory", directoryId: 15, parentId: 2, name: "I change my name")

      assert conn.status == 401
    end

    test "/api/deleteFile without permission", %{conn: conn} do
      conn = delete(conn, "/api/deleteFile/-1")
      assert conn.status == 401
    end

    test "/api/deleteDirectory without permission", %{conn: conn} do
      conn = delete(conn, "/api/deleteDirectory/1")
      assert conn.status == 401
    end
  end

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

  describe "POST /createFile" do
    test "create a file", %{conn: conn} do
      conn = post(conn, "/api/createFile", name: "example")
      assert conn.status == 200
    end

    test "create a file empty name", %{conn: conn} do
      conn = post(conn, "/api/createFile", name: "")
      assert json_response(conn, 403)["error"] == empty_file_name()
    end
  end

  describe "POST /insertContent" do
    test "save code successfully", %{conn: conn} do
      conn = post(conn, "/api/createFile", name: "example")
      id = json_response(conn, 200)["message"]
      conn = post(conn, "/api/insertContent", content: "40+2", id: id)
      assert json_response(conn, 200)["message"] == content_inserted()
    end

    test "code save fail", %{conn: conn} do
      conn = post(conn, "/api/createFile", name: "Example")
      id = json_response(conn, 200)["message"]

      conn = post(conn, "/api/insertContent", content: "40+'2'", id: id)

      assert json_response(conn, 200)["error"]["errorCode"] ==
               "TypeError: Error at line 1 in '+' operation, Incompatible types: Integer, String were found but Integer, Integer were expected"

      assert json_response(conn, 200)["error"]["line"] == 1
    end

    test "code save fail beacause empty name", %{conn: conn} do
      conn = post(conn, "/api/insertContent", content: "40+'2'")

      assert json_response(conn, 404)["error"] == file_not_found()
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
      conn = post(conn, "/api/createDirectory", name: "code")
      assert conn.status == 200

      conn = get(conn, "/api/file")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "children" => [],
                   "name" => "code",
                   "type" => "Directory"
                 }
               ],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)
    end

    test "create directory with the same name", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory", name: "code")

      conn =
        post(conn, "/api/createDirectory", name: "code")

      assert json_response(conn, 403)["error"] == directory_name_already_exits()
    end

    test "create directory with empty name", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory", name: "")

      assert json_response(conn, 403)["error"] == empty_folder_name()
    end

    test "create a subdirectory successfully", %{conn: conn} do
      conn = post(conn, "/api/createDirectory", name: "code")

      code_id = json_response(conn, 200)["message"]

      assert conn.status == 200

      conn = get(conn, "/api/file")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "children" => [],
                   "name" => "code",
                   "type" => "Directory"
                 }
               ],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)

      conn = post(conn, "/api/createDirectory", name: "code2", parentId: code_id)
      assert conn.status == 200

      conn = get(conn, "/api/file")

      response2 = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "children" => [
                     %{
                       "children" => [],
                       "name" => "code2",
                       "type" => "Directory"
                     }
                   ],
                   "name" => "code",
                   "type" => "Directory"
                 }
               ],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response2)
    end
  end

  describe "POST /editContent" do
    setup %{conn: conn} do
      # La estructura que vamos a formar es la siguiente '+' carpetas '-' ficheros
      # + Root
      #   + code
      #     + code
      #     - example "40+2"
      #     - example2 "'hola' + 'mundo'"
      #   + pj
      #     - createPj "'hola' + 'mundo'"
      #     + doThings
      #       - doThings "'hola' + 'mundo'"

      conn =
        post(conn, "/api/createDirectory", name: "code")

      code1_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile",
          directoryId: code1_id,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent",
          id: id,
          content: "40+2"
        )

      assert conn.status == 200

      conn =
        post(conn, "/api/createDirectory", name: "code", parentId: code1_id)

      code2_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile",
          directoryId: code1_id,
          name: "example2"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      conn =
        post(conn, "/api/createDirectory", name: "pj")

      pj_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile",
          directoryId: pj_id,
          name: "createPj"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      conn =
        post(conn, "/api/createDirectory", name: "do_things", parentId: pj_id)

      do_things_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile",
          directoryId: do_things_id,
          name: "do_things"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      {:ok,
       conn: conn, code1_id: code1_id, do_things_id: do_things_id, code2_id: code2_id, file_id: id}
    end

    test "edit file error", %{conn: conn} do
      conn =
        post(conn, "/api/createFile", name: "example")

      conn =
        post(conn, "/api/editFile", id: -1, content: "40+2", name: "example")

      assert conn.status == 404
    end

    test "move a directory", %{conn: conn, code1_id: directory_id, code2_id: parent_id} do
      conn =
        post(conn, "/api/editDirectory",
          id: parent_id,
          parentId: directory_id,
          name: "I change my name"
        )

      assert conn.status == 200

      conn = get(conn, "/api/file")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "children" => [
                     %{
                       "content" => "40+2",
                       "name" => "example",
                       "type" => "File"
                     },
                     %{
                       "content" => "'hola ' ++ 'mundo'",
                       "name" => "example2",
                       "type" => "File"
                     },
                     %{
                       "children" => [],
                       "name" => "I change my name",
                       "type" => "Directory"
                     }
                   ],
                   "name" => "code",
                   "type" => "Directory"
                 },
                 %{
                   "children" => [
                     %{
                       "content" => "'hola ' ++ 'mundo'",
                       "name" => "createPj",
                       "type" => "File"
                     },
                     %{
                       "children" => [
                         %{
                           "content" => "'hola ' ++ 'mundo'",
                           "name" => "do_things",
                           "type" => "File"
                         }
                       ],
                       "name" => "do_things",
                       "type" => "Directory"
                     }
                   ],
                   "name" => "pj",
                   "type" => "Directory"
                 }
               ],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)
    end

    test "move a directory inside a child", %{
      conn: conn,
      code1_id: directory_id,
      code2_id: parent_id
    } do
      conn =
        post(conn, "/api/editDirectory",
          id: directory_id,
          parentId: parent_id
        )

      assert json_response(conn, 403)["error"] == parent_into_child()
    end

    test "edit a file", %{conn: conn, file_id: file_id} do
      conn =
        post(conn, "/api/editFile",
          id: file_id,
          name: "I change my name",
          content: "Im am a metamorph content"
        )

      assert conn.status == 200

      conn = get(conn, "/api/file")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "children" => [
                     %{
                       "content" => "40+2",
                       "name" => "example",
                       "type" => "File"
                     },
                     %{
                       "content" => "'hola ' ++ 'mundo'",
                       "name" => "example2",
                       "type" => "File"
                     },
                     %{
                       "children" => [],
                       "name" => "code",
                       "type" => "Directory"
                     }
                   ],
                   "name" => "code",
                   "type" => "Directory"
                 },
                 %{
                   "children" => [
                     %{
                       "content" => "'hola ' ++ 'mundo'",
                       "name" => "createPj",
                       "type" => "File"
                     },
                     %{
                       "children" => [
                         %{
                           "content" => "Im am a metamorph content",
                           "name" => "I change my name",
                           "type" => "File"
                         }
                       ],
                       "name" => "do_things",
                       "type" => "Directory"
                     }
                   ],
                   "name" => "pj",
                   "type" => "Directory"
                 }
               ],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)
    end

    test "edit a non existing file", %{conn: conn} do
      conn =
        post(conn, "/api/editFile",
          id: -1,
          directoryId: 1,
          name: "I change my name",
          content: "Im am a metamorph content"
        )

      assert conn.status == 404

      assert json_response(conn, 404)["error"] == file_not_found()
    end

    test "edit a non existing directory", %{conn: conn} do
      conn =
        post(conn, "/api/editDirectory", directoryId: 15, parentId: 2, name: "I change my name")

      assert conn.status == 404

      assert json_response(conn, 404)["error"] == directory_not_found()
    end
  end

  describe "GET /files" do
    test "get files succesfully", %{conn: conn} do
      conn = get(conn, "/api/file", content: "40+2", name: "example")
      assert conn.status == 200
    end

    test "get overwrite documments", %{conn: conn} do
      conn = post(conn, "/api/createFile", name: "example")
      file_id = json_response(conn, 200)["message"]
      conn = post(conn, "/api/insertContent", content: "40+2", id: file_id)
      conn = post(conn, "/api/insertContent", content: "42+2", id: file_id)
      assert conn.status == 200
      conn = get(conn, "/api/file")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "content" => "42+2",
                   "name" => "example",
                   "type" => "File"
                 }
               ],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)
    end

    test "get documments succesfully", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory", name: "code")

      code_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile", directoryId: code_id, name: "example")

      file_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent", id: file_id, content: "40+2")

      assert conn.status == 200
      conn = get(conn, "/api/file")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "children" => [
                     %{
                       "content" => "40+2",
                       "name" => "example",
                       "type" => "File"
                     }
                   ],
                   "name" => "code",
                   "type" => "Directory"
                 }
               ],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)
    end

    test "get 0 documments", %{conn: conn} do
      conn = get(conn, "/api/file")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)
    end

    test "creating a complex fileSystem", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory", name: "code")

      code_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile",
          directoryId: code_id,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent",
          id: id,
          content: "40+2"
        )

      assert conn.status == 200

      conn =
        post(conn, "/api/createDirectory", name: "code", parentId: code_id)

      code2_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile",
          directoryId: code2_id,
          name: "example2"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      conn =
        post(conn, "/api/createDirectory", name: "pj")

      pj_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile",
          directoryId: pj_id,
          name: "createPj"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent",
          id: id,
          name: "createPj"
        )

      conn =
        post(conn, "/api/createDirectory", name: "do_things", parentId: pj_id)

      do_things_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile",
          directoryId: do_things_id,
          name: "do_things"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      assert conn.status == 200

      conn = get(conn, "/api/file")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "children" => [
                     %{
                       "content" => "40+2",
                       "name" => "example",
                       "type" => "File"
                     },
                     %{
                       "children" => [
                         %{
                           "content" => "'hola ' ++ 'mundo'",
                           "name" => "example2",
                           "type" => "File"
                         }
                       ],
                       "name" => "code",
                       "type" => "Directory"
                     }
                   ],
                   "name" => "code",
                   "type" => "Directory"
                 },
                 %{
                   "children" => [
                     %{
                       "content" => nil,
                       "name" => "createPj",
                       "type" => "File"
                     },
                     %{
                       "children" => [
                         %{
                           "content" => "'hola ' ++ 'mundo'",
                           "name" => "do_things",
                           "type" => "File"
                         }
                       ],
                       "name" => "do_things",
                       "type" => "Directory"
                     }
                   ],
                   "name" => "pj",
                   "type" => "Directory"
                 }
               ],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)
    end
  end

  describe "POST /createFiles" do
    test "create file", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory", name: "code")

      code_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile",
          directoryId: code_id,
          name: "example"
        )

      assert conn.status == 200
    end

    test "create file with the same name", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory", name: "code")

      code_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile",
          directoryId: code_id,
          name: "example"
        )

      conn =
        post(conn, "/api/createFile",
          directoryId: code_id,
          name: "example"
        )

      assert json_response(conn, 403)["error"] == file_name_already_exits()
    end

    test "insert content", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory", name: "code")

      code_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile",
          directoryId: code_id,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent",
          id: id,
          content: "40+2"
        )

      assert conn.status == 200
    end
  end

  describe "GET /filesById" do
    test "try get a not existing file", %{conn: conn} do
      conn = get(conn, "/api/file/1")
      assert conn.status == 404
    end

    test "try get an existing file", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory", name: "code")

      code_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile",
          directoryId: code_id,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent",
          id: id,
          content: "40+2"
        )

      conn = get(conn, "/api/file/#{id}")
      assert conn.status == 200

      response = json_response(conn, 200)["message"]

      assert %{
               "content" => "40+2",
               "contentSchema" => nil,
               "name" => "example"
             } == drop_ids(response)
    end
  end

  describe "DELETE /deleteFile" do
    test "delete a non existing file", %{conn: conn} do
      conn = delete(conn, "/api/deleteFile/-1")
      assert conn.status == 204
    end

    test "delete a existing file", %{conn: conn} do
      conn =
        post(conn, "/api/createFile", name: "example")

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent",
          content: "40+2",
          id: id
        )

      conn = delete(conn, "/api/deleteFile/#{id}")
      assert conn.status == 200
      assert json_response(conn, 200)["message"] == "FILE_DELETED"
    end

    test "delete a non existing directory", %{conn: conn} do
      conn = delete(conn, "/api/deleteDirectory/1")
      assert conn.status == 204
    end

    test "delete a existing directory without files", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory", name: "code")

      code_id = json_response(conn, 200)["message"]

      conn = delete(conn, "/api/deleteDirectory/#{code_id}")
      assert conn.status == 200
      assert json_response(conn, 200)["message"] == "DIRECTORY_DELETED"
    end

    test "delete a existing directory with files", %{conn: conn} do
      conn =
        post(conn, "/api/createDirectory", name: "code")

      code_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/createFile",
          directoryId: code_id,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent",
          id: id,
          content: "40+2"
        )

      conn =
        post(conn, "/api/createFile",
          directoryId: code_id,
          name: "example2"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/insertContent",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      conn = delete(conn, "/api/deleteDirectory/#{code_id}")
      assert conn.status == 200
      assert json_response(conn, 200)["message"] == "DIRECTORY_DELETED"

      conn = get(conn, "/api/file")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)

      conn = get(conn, "/api/file/#{id}")
      assert conn.status == 404
    end
  end

  # Función auxiliar para eliminar los IDs dinámicos para comparar estructuras
  defp drop_ids(map) when is_map(map) do
    map
    |> Map.drop(["id", "parentId", "directoryId"])
    |> Map.new(fn {key, val} -> {key, drop_ids(val)} end)
  end

  defp drop_ids(list) when is_list(list), do: Enum.map(list, &drop_ids/1)
  defp drop_ids(value), do: value
end
