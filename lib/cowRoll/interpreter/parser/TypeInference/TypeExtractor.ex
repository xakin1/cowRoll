defmodule TypeExtractor do
  @operadores [
    :mult,
    :divi,
    :plus,
    :minus,
    :assignment,
    :strict_more,
    :more_equal,
    :strict_less,
    :less_equal,
    :equal,
    :not_equal,
    :and_operation,
    :or_operation,
    :round_div,
    :mod,
    :pow,
    :concat,
    :subtract
  ]
  import TypesUtils

  # Enum: tipo del enumerado
  # expression: tupla del enumerado
  def extract_enum_types(enum, expression) do
    enum
    |> get_types(expression)
    |> Enum.map(&format_type/1)
    |> format_enum_type(enum)
  end

  # Case simple types: integers, booleans...

  # For lists
  defp get_enum_types(
         {{function, {left_expr, right_expr}, {symbol, line}}, rest},
         types
       )
       when function in @operadores do
    {function_type, _} =
      TypeInference.infer({function, {left_expr, right_expr}, {symbol, line}})

    types = MapSet.put(types, function_type)

    get_enum_types(rest, types)
  end

  defp get_enum_types({function, {left_expr, right_expr}, {symbol, line}}, types)
       when function in @operadores do
    {function_type, _} =
      TypeInference.infer({function, {left_expr, right_expr}, {symbol, line}})

    MapSet.put(types, function_type)
  end

  defp get_enum_types({type, _value, _line}, types) do
    MapSet.put(types, type)
  end

  defp get_enum_types({{type, _value, _line}, rest}, types) do
    types = MapSet.put(types, type)
    get_enum_types(rest, types)
  end

  defp get_enum_types({enum, expression}, types) when enum in [:list, :map] do
    type = "(#{extract_enum_types(enum, expression)})"
    MapSet.put(types, type)
  end

  defp get_enum_types({{enum, expression}, rest}, types) when enum in [:list, :map] do
    type = "(#{extract_enum_types(enum, expression)})"
    types = MapSet.put(types, type)
    get_enum_types(rest, types)
  end

  defp get_enum_types({{_key, {enum, expression}}, rest}, types) when enum in [:map, :list] do
    type = "(#{extract_enum_types(enum, expression)})"
    types = MapSet.put(types, type)
    get_enum_types(rest, types)
  end

  defp get_enum_types(
         {{:if_then_else, condition, then_expression, else_expression, {function, line}}, rest},
         types
       ) do
    {_, constraints} =
      TypeInference.infer(
        {:if_then_else, condition, then_expression, else_expression, {function, line}}
      )

    type = Enum.join(Map.to_list(constraints), " | ")

    types = MapSet.put(types, type)
    get_enum_types(rest, types)
  end

  defp get_enum_types(
         {:if_then_else, condition, then_expression, else_expression, {function, line}},
         types
       ) do
    {_, constraints} =
      TypeInference.infer(
        {:if_then_else, condition, then_expression, else_expression, {function, line}}
      )

    # Extraemos los valores del mapa y los convertimos en un MapSet
    types_map =
      constraints
      |> Map.values()
      |> MapSet.new()

    # Unimos el MapSet existente con el nuevo MapSet de valores
    MapSet.union(types, types_map)
  end

  # Caso de enumerado vacio
  defp get_enum_types(nil, types) do
    types
  end

  # For maps
  # Caso de enumerado vacio
  defp get_map_types(nil, types) do
    types
  end

  # Case complex types: list, maps
  defp get_map_types({_key, {enum, expression}}, types) when enum in [:map, :list] do
    type = "(#{extract_enum_types(enum, expression)})"

    MapSet.put(types, type)
  end

  defp get_map_types({{_key, {enum, expression}}, rest}, types) when enum in [:map, :list] do
    type = "(#{extract_enum_types(enum, expression)})"

    types = MapSet.put(types, type)
    get_map_types(rest, types)
  end

  defp get_map_types(
         {{_key, {:if_then_else, condition, then_expression, else_expression, {function, line}}},
          rest},
         types
       ) do
    {_, constraints} =
      TypeInference.infer(
        {:if_then_else, condition, then_expression, else_expression, {function, line}}
      )

    type = Enum.join(Map.to_list(constraints), " | ")

    types = MapSet.put(types, type)
    get_map_types(rest, types)
  end

  defp get_map_types(
         {_key, {:if_then_else, condition, then_expression, else_expression, {function, line}}},
         types
       ) do
    {_, constraints} =
      TypeInference.infer(
        {:if_then_else, condition, then_expression, else_expression, {function, line}}
      )

    # Extraemos los valores del mapa y los convertimos en un MapSet
    types_map =
      constraints
      |> Map.values()
      |> MapSet.new()

    # Unimos el MapSet existente con el nuevo MapSet de valores
    MapSet.union(types, types_map)
  end

  defp get_map_types(
         {{_key, {function, {left_expr, right_expr}, {symbol, line}}}, rest},
         types
       )
       when function in @operadores do
    {function_type, _} =
      TypeInference.infer({function, {left_expr, right_expr}, {symbol, line}})

    types = MapSet.put(types, function_type)

    get_map_types(rest, types)
  end

  defp get_map_types({_key, {function, {left_expr, right_expr}, {symbol, line}}}, types)
       when function in @operadores do
    {function_type, _} =
      TypeInference.infer({function, {left_expr, right_expr}, {symbol, line}})

    MapSet.put(types, function_type)
  end

  defp get_map_types({_key, {type, _value, _line}}, types) do
    MapSet.put(types, type)
  end

  defp get_map_types({{_key, {type, _value, _line}}, rest}, types) do
    types = MapSet.put(types, type)
    get_map_types(rest, types)
  end

  defp get_types(:list, expression), do: get_enum_types(expression, MapSet.new())
  defp get_types(:map, expression), do: get_map_types(expression, MapSet.new())

  defp format_enum_type(types_enum, enum) do
    case types_enum do
      [] ->
        "#{get_type(enum)} of #{fresh_type()}"

      _ ->
        "#{get_type(enum)} of #{Enum.join(types_enum, " | ")}"
    end
  end

  defp format_type(type) do
    case type do
      type when is_atom(type) -> get_type(type)
      _ -> type
    end
  end
end
