defmodule CowRollWeb.Controller.HelpersControllers do
  def get_user_id(conn) do
    case conn.assigns[:current_user] do
      %{"id" => user_id} -> user_id
      %{"user_id" => %{"id" => user_id}} -> user_id
      _ -> :error
    end
  end
end
