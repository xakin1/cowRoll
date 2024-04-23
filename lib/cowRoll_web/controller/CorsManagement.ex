defmodule CowRollWeb.CorsManagement do
  use CowRollWeb, :controller

  def init() do
  end

  def handle_options(conn, _params) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, OPTIONS")
    |> put_resp_header(
      "access-control-allow-headers",
      "Origin, X-Requested-With, Content-Type, Accept"
    )
    |> send_resp(204, "")
  end
end
