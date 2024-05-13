defmodule CowRollWeb.Controller.HelpersControllers do
  def get_current_user(conn), do: conn.assigns[:current_user]
end
