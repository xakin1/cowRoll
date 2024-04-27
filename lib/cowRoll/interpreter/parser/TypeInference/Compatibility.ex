defmodule Compatibility do
  import TypesUtils
  import ListUtils
  import TypeError

  def get_function_type(function, t1, line)
      when function in [:negative] do
    integer_type = get_type_integer()

    case t1 do
      ^integer_type ->
        integer_type

      t1 when is_atom(t1) ->
        integer_type

      _ ->
        raise raise_error(line, function, t1, integer_type)
    end
  end

  def get_function_type(function, t1, line)
      when function in [:not_operation] do
    boolean_type = get_type_boolean()

    case t1 do
      ^boolean_type ->
        boolean_type

      t1 when is_atom(t1) ->
        boolean_type

      _ ->
        raise raise_error(line, function, t1, boolean_type)
    end
  end

  def get_function_type(function, t1, t2, line)
      when function in [:mult, :divi, :round_div, :plus, :minus, :mod, :pow] do
    integer_type = get_type_integer()

    case {t1, t2} do
      {^integer_type, ^integer_type} ->
        integer_type

      {t1, t2} when is_atom(t1) and is_atom(t2) ->
        integer_type

      {t1, ^integer_type} when is_atom(t1) ->
        integer_type

      {^integer_type, t2} when is_atom(t2) ->
        integer_type

      _ ->
        compatible?(function, t1, t2, integer_type, integer_type, line)
    end
  end

  def get_function_type(function, t1, t2, line)
      when function == :range do
    integer_type = get_type_integer()

    case {t1, t2} do
      {^integer_type, ^integer_type} ->
        integer_type

      {t1, t2} when is_atom(t1) and is_atom(t2) ->
        integer_type

      {t1, ^integer_type} when is_atom(t1) ->
        integer_type

      {^integer_type, t2} when is_atom(t2) ->
        integer_type

      _ ->
        compatible?(function, t1, t2, integer_type, integer_type, line)
    end
  end

  def get_function_type(function, t1, t2, line)
      when function in [:strict_more, :more_equal, :strict_less, :less_equal] do
    boolean_type = get_type_boolean()
    integer_type = get_type_integer()

    case {t1, t2} do
      {^integer_type, ^integer_type} ->
        boolean_type

      {^boolean_type, ^boolean_type} ->
        boolean_type

      {^boolean_type, ^integer_type} ->
        boolean_type

      {^integer_type, ^boolean_type} ->
        boolean_type

      # Casos en los que t1 o t2 son variables
      {t1, ^integer_type} when is_atom(t1) ->
        boolean_type

      {^integer_type, t2} when is_atom(t2) ->
        boolean_type

      {t1, ^boolean_type} when is_atom(t1) ->
        boolean_type

      {^boolean_type, t2} when is_atom(t2) ->
        boolean_type

      {t1, t2} when is_atom(t1) and is_atom(t2) ->
        boolean_type

      _ ->
        compatible?(function, t1, t2, [boolean_type, integer_type], boolean_type, line)
    end
  end

  def get_function_type(function, t1, t2, line)
      when function in [:and_operation, :or_operation] do
    boolean_type = get_type_boolean()

    case {t1, t2} do
      {^boolean_type, ^boolean_type} ->
        boolean_type

      {t1, ^boolean_type} when is_atom(t1) ->
        boolean_type

      {^boolean_type, t2} when is_atom(t2) ->
        boolean_type

      {t1, t2} when is_atom(t1) and is_atom(t2) ->
        boolean_type

      _ ->
        compatible?(function, t1, t2, boolean_type, boolean_type, line)
    end
  end

  def get_function_type(function, t1, t2, line) when function in [:concat, :subtract] do
    string_type = get_type_string()
    list_type = get_type_list()

    case {t1, t2} do
      {^string_type, ^string_type} ->
        string_type

      {t1, ^string_type} when is_atom(t1) ->
        string_type

      {^string_type, t2} when is_atom(t2) ->
        string_type

      # No podemos saber si es String o una lista
      {t1, t2} when is_atom(t1) and is_atom(t2) ->
        "#{list_type} of #{fresh_type()} | #{string_type}"

      _ ->
        try do
          compatible?(function, t1, t2, string_type, string_type, line)
        rescue
          TypeError ->
            case split_list_and_types(t1) do
              {enum, _} ->
                if is_list?(enum) do
                  list_type
                else
                  raise_error(line, function, t1, t2, string_type)
                end

              false ->
                raise_error(line, function, t1, t2, string_type)
            end
        end
    end
  end

  def get_function_type(function, _t1, _t2, _line)
      when function in [:equal, :not_equal],
      do: get_type_boolean()

  def get_index_type(var_type, enum) do
    integer_type = get_type_integer()
    string_type = get_type_string()
    list_type = get_type_list()
    map_type = get_type_map()
    # Comprobamos que el índice es de un tipo correcto
    case {var_type, enum} do
      {^integer_type, ^list_type} ->
        var_type

      {^integer_type, ^string_type} ->
        var_type

      {^integer_type, ^map_type} ->
        var_type

      {var_type, ^list_type} when is_atom(var_type) ->
        var_type

      {var_type, ^string_type} when is_atom(var_type) ->
        var_type

      {var_type, ^map_type} when is_atom(var_type) ->
        var_type

      {^string_type, ^map_type} ->
        var_type

      {^string_type, ^string_type} ->
        var_type

      {_, ^map_type} ->
        raise raise_index_map_error(var_type)

      {_, ^string_type} ->
        raise raise_index_error(var_type)

      {_, ^list_type} ->
        raise raise_index_error(var_type)
    end
  end

  def get_parameter_type(parameter_types, constraints, function_name, line) do
    case Map.get(constraints, "#{function_name}_parameters") do
      nil ->
        # Caso de que sea una función importada de un modulo
        constraints

      parameters ->
        get_parameter_type_aux(parameters, parameter_types, function_name, constraints, line)
    end
  end

  defp get_parameter_type_aux(parameters, parameter_types, function_name, constraints, line) do
    parameters_found = Enum.count(parameter_types)
    parameters_expected = map_size(parameters)

    if parameters_found != parameters_expected do
      raise_error_parameters_type(line, function_name, parameters_expected,parameters_found)

    else
      check_parameters(parameters, parameter_types, function_name, constraints, line)
    end
  end

  defp check_parameters(parameters, parameter_types, function_name, constraints, line) do
    keys = Map.keys(parameters)

    {all_matched, updated_constraints, error_message} =
      Enum.with_index(parameter_types, 0)
      |> Enum.reduce({true, constraints, nil}, fn {parameter, index},
                                                  {acc_match, acc_constraints, acc_error} ->
        key = Enum.at(keys, index)

        case Map.get(parameters, key) do
          value when is_atom(value) and not is_atom(parameter) ->
            {acc_match, Map.put(acc_constraints, value, parameter), acc_error}

          _ when is_atom(parameter) ->
            {acc_match, acc_constraints, acc_error}

          value when value == parameter ->
            {acc_match, acc_constraints, acc_error}

          value ->
            {false, acc_constraints,
             "Error at line #{line}: Type mismatch in function '#{function_name}', expected parameter '#{to_string(key)}': #{value} but got '#{parameter}'"}
        end
      end)

    if all_matched do
      updated_constraints
    else
      raise TypeError, message: error_message, line: line
    end
  end

  # En el caso de que en una operación haya un enumerado indexado
  # tenemos que comprobar los posibles tipos del enumerado
  defp compatible?(function, t1, t2, type, returning_type, line) do
    t1_aux = extract_types(t1)
    t2_aux = extract_types(t2)
    t1_enum? = is_list(t1_aux)

    t2_enum? = is_list(t2_aux)

    if check_compatible(t1_enum?, t2_enum?, t1_aux, t2_aux, type) do
      returning_type
    else
      raise raise_error(line, function, t1, t2, returning_type)
    end
  end

  defp check_compatible(t1_enum?, t2_enum?, t1, t2, type) when is_list(type) do
    case {t1_enum?, t2_enum?} do
      {true, true} ->
        {compatible1, _} = contains_any?(t1, type)
        {compatible2, _} = contains_any?(t2, type)
        compatible1 and compatible2

      {true, false} ->
        {compatible1, _} = contains_any?(t1, type)
        compatible1 and (Enum.member?(type, t2) or is_atom(t2))

      {false, true} ->
        {compatible2, _} = contains_any?(t2, type)
        compatible2 and (Enum.member?(type, t1) or is_atom(t1))

      _ ->
        false
    end
  end

  defp check_compatible(t1_enum?, t2_enum?, t1, t2, type) do
    case {t1_enum?, t2_enum?} do
      {true, true} ->
        Enum.member?(t1, type) and
          Enum.member?(t2, type)

      {true, false} ->
        Enum.member?(t1, type) and (type == t2 or is_atom(t2))

      {false, true} ->
        Enum.member?(t2, type) and (type == t1 or is_atom(t1))

      _ ->
        false
    end
  end

  defp extract_types(type) when is_atom(type), do: type
  defp extract_types("List of" <> type), do: "List of" <> type
  defp extract_types("Map of" <> type), do: "Map of" <> type
  defp extract_types(type) when is_list(type), do: type

  defp extract_types(type) do
    if String.contains?(type, " | ") do
      String.split(type, " | ")
    else
      type
    end
  end

  def contains_any?(list, types) when is_list(types) do
    case Enum.find(types, &Enum.member?(list, &1)) do
      match -> {true, match}
    end
  end
end
