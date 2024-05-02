defmodule CowRollWeb.ErrorView do
  def render("500.json", _assigns) do
    %{error: "Internal server error"}
  end

  def render("404.json", _assigns) do
    %{error: "Resource not found"}
  end

  def render("400.json", _assigns) do
    %{error: "Bad request"}
  end

  def template_not_found(_, assigns) do
    render("500.json", assigns)
  end
end
