defmodule CowRollWeb.UserApiTest do
  use CowRollWeb.ConnCase, async: true
  import CowRollWeb.ErrorCodes
  import CowRollWeb.SuccesCodes
  use ExUnit.Case

  # Bloque setup que solo se aplica a este módulo de pruebas
  setup %{conn: conn} do
    conn = post(conn, "/api/signUp", username: "sujeto1", password: "aAcs1234.")
    conn = post(conn, "/api/login", username: "sujeto1", password: "aAcs1234.")
    token = json_response(conn, 200)["message"]
    conn = build_conn() |> put_req_header("authorization", "Bearer #{token}")

    {:ok, conn: conn}
  end

  describe "GET /sheets" do
    test "get sheets succesfully", %{conn: conn} do
      conn = get(conn, "/api/sheet/", content: "40+2", name: "example")
      assert conn.status == 200
    end

    test "get overwrite documments", %{conn: conn} do
      conn = post(conn, "/api/sheet/create", name: "example")
      sheet_id = json_response(conn, 200)["message"]
      conn = post(conn, "/api/sheet/save", content: "40+2", id: sheet_id)
      assert conn.status == 200
      conn = get(conn, "/api/sheet")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "content" => "40+2",
                   "name" => "example",
                   "type" => "Sheet"
                 }
               ],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)
    end

    test "get documments succesfully", %{conn: conn} do
      conn =
        post(conn, "/api/directory/create", name: "sheet")

      sheet_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/create", directoryId: sheet_id, name: "example")

      sheet_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/save", id: sheet_id, content: "40+2")

      assert conn.status == 200
      conn = get(conn, "/api/sheet")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "children" => [
                     %{
                       "content" => "40+2",
                       "name" => "example",
                       "type" => "Sheet"
                     }
                   ],
                   "name" => "sheet",
                   "type" => "Directory"
                 }
               ],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)
    end

    test "get 0 documments", %{conn: conn} do
      conn = get(conn, "/api/sheet")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)
    end

    test "creating a complex sheetSystem", %{conn: conn} do
      conn =
        post(conn, "/api/directory/create", name: "sheet")

      sheet_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/create",
          directoryId: sheet_id,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/save",
          id: id,
          content: "40+2"
        )

      assert conn.status == 200

      conn =
        post(conn, "/api/directory/create", name: "sheet", parentId: sheet_id)

      sheet2_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/create",
          directoryId: sheet2_id,
          name: "example2"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/save",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      conn =
        post(conn, "/api/directory/create", name: "pj")

      pj_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/create",
          directoryId: pj_id,
          name: "createPj"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/save",
          id: id,
          name: "createPj"
        )

      conn =
        post(conn, "/api/directory/create", name: "do_things", parentId: pj_id)

      do_things_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/create",
          directoryId: do_things_id,
          name: "do_things"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/save",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      assert conn.status == 200

      conn = get(conn, "/api/sheet")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "children" => [
                     %{
                       "content" => "40+2",
                       "name" => "example",
                       "type" => "Sheet"
                     },
                     %{
                       "children" => [
                         %{
                           "content" => "'hola ' ++ 'mundo'",
                           "name" => "example2",
                           "type" => "Sheet"
                         }
                       ],
                       "name" => "sheet",
                       "type" => "Directory"
                     }
                   ],
                   "name" => "sheet",
                   "type" => "Directory"
                 },
                 %{
                   "children" => [
                     %{
                       "content" => nil,
                       "name" => "createPj",
                       "type" => "Sheet"
                     },
                     %{
                       "children" => [
                         %{
                           "content" => "'hola ' ++ 'mundo'",
                           "name" => "do_things",
                           "type" => "Sheet"
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

  describe "GET /sheet/file" do
    test "try get a not existing file", %{conn: conn} do
      conn = get(conn, "/api/sheet/1")
      assert conn.status == 404
    end

    test "try get an existing file", %{conn: conn} do
      conn =
        post(conn, "/api/directory/create", name: "sheet")

      sheet_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/create",
          directoryId: sheet_id,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/save",
          id: id,
          content: "40+2"
        )

      conn = get(conn, "/api/sheet/#{id}")
      assert conn.status == 200

      response = json_response(conn, 200)["message"]

      assert %{
               "content" => "40+2",
               "name" => "example",
               "type" => "Sheet"
             } == drop_ids(response)
    end
  end

  describe "POST /sheet/create" do
    test "save sheet successfully", %{conn: conn} do
      conn = post(conn, "/api/sheet/create", name: "example")
      id = json_response(conn, 200)["message"]
      conn = post(conn, "/api/sheet/save", content: "40+2", id: id)
      assert json_response(conn, 200)["message"] == content_inserted()
    end

    test "code sheet fail beacause empty name", %{conn: conn} do
      conn = post(conn, "/api/sheet/save", content: "40+'2'")

      assert json_response(conn, 404)["error"] == file_not_found()
    end
  end

  describe "DELETE /sheet/remove" do
    test "delete a non existing file", %{conn: conn} do
      conn = delete(conn, "/api/sheet/remove/-1")
      assert conn.status == 204
    end

    test "delete a existing file", %{conn: conn} do
      conn =
        post(conn, "/api/sheet/create", name: "example")

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/save",
          content: "40+2",
          id: id
        )

      conn = delete(conn, "/api/sheet/remove/#{id}")
      assert conn.status == 200
      assert json_response(conn, 200)["message"] == "FILE_DELETED"
    end

    test "delete a non existing directory", %{conn: conn} do
      conn = delete(conn, "/api/directory/delete/1")
      assert conn.status == 204
    end

    test "delete a existing directory without files", %{conn: conn} do
      conn =
        post(conn, "/api/directory/create", name: "sheet")

      sheet_id = json_response(conn, 200)["message"]

      conn = delete(conn, "/api/directory/delete/#{sheet_id}")
      assert conn.status == 200
      assert json_response(conn, 200)["message"] == "DIRECTORY_DELETED"
    end

    test "delete a existing directory with files", %{conn: conn} do
      conn =
        post(conn, "/api/directory/create", name: "sheet")

      sheet_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/create",
          directoryId: sheet_id,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/save",
          id: id,
          content: "40+2"
        )

      conn =
        post(conn, "/api/sheet/create",
          directoryId: sheet_id,
          name: "example2"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/sheet/save",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      conn = delete(conn, "/api/directory/delete/#{sheet_id}")
      assert conn.status == 200
      assert json_response(conn, 200)["message"] == "DIRECTORY_DELETED"

      conn = get(conn, "/api/sheet")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)

      conn = get(conn, "/api/sheet/#{id}")
      assert conn.status == 404
    end
  end
end
