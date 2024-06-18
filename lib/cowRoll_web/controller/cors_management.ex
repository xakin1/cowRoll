defmodule CowRollWeb.CorsManagement do
  use CowRollWeb, :controller
  @domain "http://localhost:4000"
  def init() do
  end

  def handle_options(conn, _params) do
    conn
    |> put_resp_header("access-control-allow-origin", @domain)
    |> put_resp_header("access-control-allow-methods", "GET, POST, DELETE, OPTIONS")
    |> put_resp_header(
      "access-control-allow-headers",
      "Origin, X-Requested-With, Content-Type, Accept"
    )
    |> put_resp_header("access-control-allow-credentials", "true")
    |> send_resp(204, "")
  end

  def call(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", @domain)
    |> put_resp_header("access-control-allow-methods", "GET, POST, DELETE, OPTIONS")
    |> put_resp_header(
      "access-control-allow-headers",
      "Origin, X-Requested-With, Content-Type, Accept"
    )
    |> put_resp_header("access-control-allow-credentials", "true")
    |> put_resp_header("access-control-expose-headers", "Content-Disposition")
  end
end
