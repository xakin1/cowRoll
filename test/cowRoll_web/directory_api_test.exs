defmodule CowRollWeb.DirectoryApiTest do
  use CowRollWeb.ConnCase, async: true
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
      conn = get(conn, "/api/file/", content: "40+2", name: "example")
      assert conn.status == 200
    end

    test "get overwrite documments", %{conn: conn} do
      conn =
        post(conn, "/api/directory/create", name: "do_things")

      do_things_id = json_response(conn, 200)["message"]

      conn =
        post(conn, "/api/directory/create", type: "Rol", name: "example", parentId: do_things_id)

      conn = get(conn, "/api/file")

      response = json_response(conn, 200)["message"]

      assert %{
               "children" => [
                 %{
                   "children" => [],
                   "name" => "Roles",
                   "type" => "Directory"
                 },
                 %{
                   "children" => [
                     %{
                       "children" => [
                         %{
                           "children" => [],
                           "name" => "Sheets",
                           "type" => "Directory"
                         },
                         %{
                           "children" => [],
                           "name" => "Codes",
                           "type" => "Directory"
                         }
                       ],
                       "description" => nil,
                       "image" => nil,
                       "name" => "example",
                       "type" => "Rol"
                     }
                   ],
                   "name" => "do_things",
                   "type" => "Directory"
                 }
               ],
               "name" => "Root",
               "type" => "Directory"
             } == drop_ids(response)
    end
  end
end
