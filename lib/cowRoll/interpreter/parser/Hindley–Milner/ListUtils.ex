defmodule ListUtils do
  import TypesUtils

  # Quitamos el prefijo List of y obtenemos un array con los tipos  def extract_types(input, level) do  def extract_types(input, level) do
  def extract_types(input, level) do
    input
    |> normalize_input()
    |> split_and_extract(level)
    |> format_input()
  end

  defp format_input(input) when is_list(input) do
    case input do
      [single] -> single
      _ -> Enum.join(input, " | ")
    end
  end

  defp format_input(input), do: input

  defp normalize_input(input) do
    # Se elimina el "List of " o "Map of " inicial si está presente
    case input do
      "List of " <> types -> types
      "Map of " <> types -> types
      _ -> input
    end
  end

  defp split_and_extract(input, 1) do
    input
  end

  defp split_and_extract(input, level) when level > 1 do
    input
    |> String.split("|")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&remove_outer_type_and_parentheses/1)
    |> Enum.filter(fn item ->
      String.contains?(item, "List of") or String.contains?(item, "Map of")
    end)
    |> Enum.map(fn item ->
      case item do
        "" -> []
        _ -> [item]
      end
    end)
    |> List.flatten()
    |> Enum.uniq()
  end

  defp remove_outer_type_and_parentheses(input) do
    input
    |> remove_list_of_from_segment()
    |> remove_map_of_from_segment()
    |> remove_outer_parentheses()
  end

  defp remove_list_of_from_segment(input) do
    Regex.replace(~r/^\(?\s*List of /, input, "")
  end

  defp remove_map_of_from_segment(input) do
    Regex.replace(~r/^\(?\s*Map of /, input, "")
  end

  defp remove_outer_parentheses(input) do
    if String.starts_with?(input, "(") && String.ends_with?(input, ")") do
      trimmed = String.trim_leading(input, "(")
      trimmed = String.trim_trailing(trimmed, ")")

      if trimmed == "" do
        ""
      else
        trimmed
      end
    else
      input
    end
  end

  def get_enum_type(input) do
    case input do
      "List" <> _ -> get_type_list()
      "Map" <> _ -> get_type_map()
      _ -> input
    end
  end

  def split_list_and_types(input, levels \\ 1) do
    case input do
      "List" <> _ ->
        {get_type_list(), extract_types(input, levels)}

      "Map" <> _ ->
        {get_type_map(), extract_types(input, levels)}

      input when is_atom(input) ->
        {get_type_map(), fresh_type()}

      _ ->
        raise "Unexpected error"
    end
  end
end
