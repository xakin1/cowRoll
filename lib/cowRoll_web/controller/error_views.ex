defmodule CowRollWeb.ErrorJSON do
  def render("500.json", _assigns) do
    %{error: "Internal server error"}
  end

  def render("404.json", %{reason: %Phoenix.Router.NoRouteError{conn: conn}}) do
    %{error: "Resource not found", url: conn.request_path}
  end

  def render("404.json", _assigns) do
    %{error: "Resource not found"}
  end

  def render("401.json", _assigns) do
    %{error: "Unauthorized"}
  end

  def render("400.json", _assigns) do
    %{error: "Bad request"}
  end

  def template_not_found(_, assigns) do
    render("500.json", assigns)
  end
end
