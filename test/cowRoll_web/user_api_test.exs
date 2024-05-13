defmodule CowRollWeb.UserApiTest do
  use CowRollWeb.ConnCase, async: true
  import CowRollWeb.ErrorCodes
  import CowRollWeb.SuccesCodes
  use ExUnit.Case

  describe "POST /signUp" do
    test "signUp without password", %{conn: conn} do
      conn = post(conn, "/api/signUp", username: "sujeto1")
      assert json_response(conn, 403)["error"] == empty_password()
    end

    test "signUp minimun length", %{conn: conn} do
      conn = post(conn, "/api/signUp", username: "sujeto1", password: "a1234.")
      assert json_response(conn, 403)["error"] == minimun_length()
    end

    test "signUp uper case", %{conn: conn} do
      conn = post(conn, "/api/signUp", username: "sujeto1", password: "a1234567.")
      assert json_response(conn, 403)["error"] == uper_case()
    end

    test "signUp lower case", %{conn: conn} do
      conn = post(conn, "/api/signUp", username: "sujeto1", password: "A1234567.")
      assert json_response(conn, 403)["error"] == lower_case()
    end

    test "signUp digits", %{conn: conn} do
      conn = post(conn, "/api/signUp", username: "sujeto1", password: "Abcdefgh.")
      assert json_response(conn, 403)["error"] == digits()
    end

    test "signUp special characters", %{conn: conn} do
      conn = post(conn, "/api/signUp", username: "sujeto1", password: "Abcdefghi1")
      assert json_response(conn, 403)["error"] == special_characteres()
    end

    test "signUp empty username", %{conn: conn} do
      conn = post(conn, "/api/signUp", username: "", password: "Abcdefghi1")
      assert json_response(conn, 403)["error"] == special_characteres()
    end

    test "signUp without username", %{conn: conn} do
      conn = post(conn, "/api/signUp", password: "Abcdefghi1")
      assert json_response(conn, 403)["error"] == special_characteres()
    end

    test "signUp successfully", %{conn: conn} do
      conn = post(conn, "/api/signUp", username: "sujeto1", password: "aAcs1234.")
      assert json_response(conn, 200)
    end

    test "signUp duplicate username", %{conn: conn} do
      conn = post(conn, "/api/signUp", username: "sujeto1", password: "aAcs1234.")
      conn = post(conn, "/api/signUp", username: "sujeto1", password: "aAcs1234.")

      assert json_response(conn, 403)["error"] == user_name_already_exits()
    end
  end

  describe "POST /login" do
    test "login successfully", %{conn: conn} do
      conn = post(conn, "/api/signUp", username: "sujeto1", password: "aAcs1234.")
      assert json_response(conn, 200)["message"]
      conn = post(conn, "/api/login", username: "sujeto1", password: "aAcs1234.")
      assert json_response(conn, 200)["message"]
    end
  end
end
