defmodule Substitutions do
  # Función para manejar la sustitución
  # Función principal para manejar la sustitución
  def substitution(type, constraints) when is_atom(type) do
    Map.get(constraints, type, type)
  end

  def substitution(type, constraints) do
    type
    |> parse_types()
    |> Enum.map(&replace_type(&1, constraints))
    |> Enum.join(" | ")
  end

  # Parsear la cadena de entrada en componentes individuales
  defp parse_types(types) do
    # Asumiendo el uso de una expresión regular para dividir correctamente los tipos, manteniendo grupos entre paréntesis intactos
    Regex.split(~r/(?<=\))\s*\|\s*(?=\()|(?<!\))\s*\|\s*(?!\()/, types)
    |> Enum.map(&String.trim/1)
  end

  # Reemplazar un tipo individual con su valor en el mapa si existe
  defp replace_type(type, constraints) do
    case type do
      # Para tipos complejos anidados, se necesita analizar y sustituir recursivamente
      "List of " <> rest ->
        "List of " <> replace_type(rest, constraints)

      "Map of " <> rest ->
        "Map of " <> replace_type(rest, constraints)

      _ ->
        extract_and_replace(type, constraints)
    end
  end

  # Extraer el identificador del tipo y reemplazar con el mapa, si es posible
  defp extract_and_replace(type, constraints) do
    # Solo convierte a átomo si ya existe
    try do
      type_id = String.to_existing_atom(type)
      Map.get(constraints, type_id, type)
    rescue
      _ -> type
    end
  end
end
