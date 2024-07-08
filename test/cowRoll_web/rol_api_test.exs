defmodule CowRollWeb.RolApiTest do
  use CowRollWeb.ConnCase, async: true
  import CowRollWeb.ErrorCodes
  import CowRollWeb.SuccesCodes
  use ExUnit.Case
  @file_type "Rol"

  # Bloque setup que solo se aplica a este módulo de pruebas
  setup %{conn: conn} do
    conn = post(conn, "/api/signUp", username: "sujeto1", password: "aAcs1234.")
    conn = post(conn, "/api/login", username: "sujeto1", password: "aAcs1234.")
    token = json_response(conn, 200)["message"]
    conn = build_conn() |> put_req_header("authorization", "Bearer #{token}")

    {:ok, conn: conn}
  end

  describe "GET /roles" do
    test "get roles succesfully", %{conn: conn} do
      conn = get(conn, "/api/file/", content: "40+2", name: "example")
      assert conn.status == 200
    end

    test "get overwrite documments", %{conn: conn} do
      conn = post(conn, "/api/file/create", type: "Rol", name: "example")
      rol_id = json_response(conn, 200)["message"]
      conn = post(conn, "/api/file/save", type: "Rol", content: "40+2", id: rol_id)
      assert conn.status == 200
      conn = get(conn, "/api/file")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "description" => nil,
                   "image" => nil,
                   "name" => "example",
                   "type" => "Rol"
                 }
               ],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)
    end

    test "get documments succesfully", %{conn: conn} do
      conn =
        post(conn, "/api/directory/create", type: "Rol", name: "rol")

      rol_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/create", type: "Rol", directoryId: rol_id, name: "example")

      rol_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/save", type: "Rol", id: rol_id, content: "40+2")

      assert conn.status == 200
      conn = get(conn, "/api/file")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "children" => [
                     %{
                       "description" => nil,
                       "image" => nil,
                       "name" => "example",
                       "type" => "Rol"
                     }
                   ],
                   "name" => "rol",
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

    test "creating a complex rolSystem", %{conn: conn} do
      conn =
        post(conn, "/api/directory/create", type: "Rol", name: "rol")

      rol_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/create",
          type: "Rol",
          directoryId: rol_id,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/save",
          type: "Rol",
          id: id,
          content: "40+2"
        )

      assert conn.status == 200

      conn =
        post(conn, "/api/directory/create", type: "Rol", name: "rol", parentId: rol_id)

      rol2_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/create",
          type: "Rol",
          directoryId: rol2_id,
          name: "example2"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/save",
          type: "Rol",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      conn =
        post(conn, "/api/directory/create", type: "Rol", name: "pj")

      pj_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/create",
          type: "Rol",
          directoryId: pj_id,
          name: "createPj"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/save",
          type: "Rol",
          id: id,
          name: "createPj"
        )

      conn =
        post(conn, "/api/directory/create", type: "Rol", name: "do_things", parentId: pj_id)

      do_things_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/create",
          type: "Rol",
          directoryId: do_things_id,
          name: "do_things"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/save",
          type: "Rol",
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
                       "description" => nil,
                       "image" => nil,
                       "name" => "example",
                       "type" => "Rol"
                     },
                     %{
                       "children" => [
                         %{
                           "description" => nil,
                           "image" => nil,
                           "name" => "example2",
                           "type" => "Rol"
                         }
                       ],
                       "name" => "rol",
                       "type" => "Directory"
                     }
                   ],
                   "name" => "rol",
                   "type" => "Directory"
                 },
                 %{
                   "children" => [
                     %{
                       "description" => nil,
                       "image" => nil,
                       "name" => "createPj",
                       "type" => "Rol"
                     },
                     %{
                       "children" => [
                         %{
                           "description" => nil,
                           "image" => nil,
                           "name" => "do_things",
                           "type" => "Rol"
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

  describe "GET /rol/file" do
    test "try get a not existing file", %{conn: conn} do
      conn = get(conn, "/api/file/1")
      assert conn.status == 404
    end

    test "try get an existing file", %{conn: conn} do
      conn =
        post(conn, "/api/directory/create", type: "Rol", name: "rol")

      rol_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/create",
          type: "Rol",
          directoryId: rol_id,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/save",
          type: "Rol",
          id: id,
          content: "40+2"
        )

      conn = get(conn, "/api/file/#{id}")
      assert conn.status == 200

      response = json_response(conn, 200)["message"]

      assert %{
               "description" => nil,
               "image" => nil,
               "name" => "example",
               "type" => "Rol"
             } == drop_ids(response)
    end
  end

  describe "POST /rol/create" do
    test "save rol successfully", %{conn: conn} do
      conn = post(conn, "/api/file/create", type: "Rol", name: "example")
      id = json_response(conn, 200)["message"]
      conn = post(conn, "/api/file/save", type: "Rol", content: "40+2", id: id)
      assert json_response(conn, 200)["message"] == content_inserted()
    end

    test "code rol fail beacause empty name", %{conn: conn} do
      conn = post(conn, "/api/file/save", type: "Rol", content: "40+'2'")

      assert json_response(conn, 404)["error"] == file_not_found()
    end
  end

  describe "DELETE /rol/delete" do
    test "delete a non existing file", %{conn: conn} do
      conn = delete(conn, "/api/file/delete/-1")
      assert conn.status == 204
    end

    test "delete a existing file", %{conn: conn} do
      conn =
        post(conn, "/api/file/create", type: "Rol", name: "example")

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/save",
          type: "Rol",
          content: "40+2",
          id: id
        )

      conn = delete(conn, "/api/file/delete/#{id}")
      assert conn.status == 200
      assert json_response(conn, 200)["message"] == "FILE_DELETED"
    end

    test "delete a non existing directory", %{conn: conn} do
      conn = delete(conn, "/api/directory/delete/1")
      assert conn.status == 204
    end

    test "delete a existing directory without files", %{conn: conn} do
      conn =
        post(conn, "/api/directory/create", type: "Rol", name: "rol")

      rol_id = json_response(conn, 200)["message"]

      conn = delete(conn, "/api/directory/delete/#{rol_id}")
      assert conn.status == 200
      assert json_response(conn, 200)["message"] == "DIRECTORY_DELETED"
    end

    test "delete a existing directory with files", %{conn: conn} do
      conn =
        post(conn, "/api/directory/create", type: "Rol", name: "rol")

      rol_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/create",
          type: "Rol",
          directoryId: rol_id,
          name: "example"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/save",
          type: "Rol",
          id: id,
          content: "40+2"
        )

      conn =
        post(conn, "/api/file/create",
          type: "Rol",
          directoryId: rol_id,
          name: "example2"
        )

      id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/file/save",
          type: "Rol",
          id: id,
          content: "'hola ' ++ 'mundo'"
        )

      conn = delete(conn, "/api/directory/delete/#{rol_id}")
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
end
