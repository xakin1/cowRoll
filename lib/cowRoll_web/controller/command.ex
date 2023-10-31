defmodule CowRollWeb.ApiCommandController do
  use Attack, :do_attack
  use CowRollWeb, :controller

  def get(conn, _) do
    # Lógica para manejar solicitudes GET
    text(conn, "Solicitud GET exitosa")
  end

  def parse_command(conn, _) do
    command = conn.body_params["command"]

    case command["name"] do
      "attack" -> attack(conn, command)
      _ -> text(conn, "Unknow command")
    end
  end

  defp attack(conn, command) do
    case do_attack(command) do
      {:ok, false} ->
        text(conn, "Result: Missed hit")

      {:ok, list_of_results, total_damage} ->
        result_string = list_of_results_to_string(list_of_results)

        text(conn, "Result: Daño total causado al enemigo #{total_damage} \n" <> result_string)

      {:ok, :critical, list_of_results, total_damage} ->
        result_string = list_of_results_to_string(list_of_results)

        text(
          conn,
          "Result:!Crítico¡ Daño total causado al enemigo #{total_damage} \n" <> result_string
        )

      {:error, error} ->
        send_resp(conn, 500, "Error: #{error}")
    end
  end

  defp list_of_results_to_string(list_of_results) do
    Enum.reduce(list_of_results, "", fn {dice, result}, acc ->
      acc <> "#{dice["dice"]} #{dice["dmgType"]}: dado sacado #{result}\n"
    end)
  end
end
