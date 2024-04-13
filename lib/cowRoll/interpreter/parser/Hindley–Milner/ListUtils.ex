defmodule ListUtils do
  import TypesUtils

  # Quitamos el prefijo List of y obtenemos un array con los tipos  def extract_types(input, level) do  def extract_types(input, level) do
  def extract_types(input, level) do
    input = normalize_input(input)
    input = split_and_extract(input, level)
    format_input(input)
  end

  defp format_input(input) when is_list(input) do
    case input do
      [single] -> single
      [] -> nil
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
    |> split_types()
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&relevant_type?/1)
    |> Enum.map(&remove_outer_type_and_parentheses/1)
    |> List.flatten()
    |> handle_single_element()
    |> Enum.uniq()
    |> Enum.map(fn item -> split_and_extract(item, level - 1) end)
  end

  defp handle_single_element([single]) do
    [remove_outer_parentheses(single)]
  end

  defp handle_single_element(list), do: list

  defp relevant_type?(item) do
    String.contains?(item, "List of") or String.contains?(item, "Map of")
  end

  defp remove_outer_type_and_parentheses(input) do
    {_, types} =
      input
      |> remove_outer_parentheses()
      |> split_list_and_types

    Enum.map(split_types(types), &String.trim/1)
  end

  defp remove_outer_parentheses(input) do
    if String.starts_with?(input, "(") && String.ends_with?(input, ")") do
      trimmed = String.trim_leading(input, "(")

      trimmed =
        if String.ends_with?(trimmed, ")") do
          # Si es así, quita el último carácter
          String.slice(trimmed, 0..-2)
        else
          # Si no, devuelve el string original
          trimmed
        end

      if trimmed == "" do
        ""
      else
        trimmed
      end
    else
      input
    end
  end

  def split_types(input) do
    parts = do_split(input, [], 0, "")
    Enum.reverse(parts)
  end

  defp do_split("", acc, 0, current_part), do: [current_part | acc]
  defp do_split("", acc, _count, _current_part), do: acc

  defp do_split(")" <> rest, acc, count, current_part) when count > 0,
    do: do_split(rest, acc, count - 1, current_part <> ")")

  defp do_split("(" <> rest, acc, count, current_part),
    do: do_split(rest, acc, count + 1, current_part <> "(")

  defp do_split("|" <> rest, acc, 0, current_part),
    do: do_split(rest, [current_part | acc], 0, "")

  defp do_split("|" <> rest, acc, count, current_part),
    do: do_split(rest, acc, count, current_part <> "|")

  defp do_split(<<char, rest::binary>>, acc, count, current_part),
    do: do_split(rest, acc, count, current_part <> <<char>>)

  # Devuelve false en el caso de que no sea un enumerado
  @spec split_list_and_types(any(), any()) :: false | {<<_::24, _::_*8>>, any()}
  def split_list_and_types(input, levels \\ 1) do
    case input do
      "List" <> _ ->
        {get_type_list(), extract_types(input, levels)}

      "Map" <> _ ->
        {get_type_map(), extract_types(input, levels)}

      input when is_atom(input) ->
        {get_type_map(), fresh_type()}

      _ ->
        false
    end
  end
end
