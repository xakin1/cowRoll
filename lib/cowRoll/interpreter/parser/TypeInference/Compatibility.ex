defmodule Compatibility do
  import TypesUtils
  import ListUtils

  def get_function_type(function, t1, line)
      when function in [:negative] do
    integer_type = get_type_integer()

    case t1 do
      ^integer_type ->
        integer_type

      t1 when is_atom(t1) and is_atom(t1) ->
        integer_type

      _ ->
        raise TypeError.raise_error(line, function, t1, integer_type)
    end
  end

  def get_function_type(function, t1, line)
      when function in [:not_operation] do
    boolean_type = get_type_boolean()

    case t1 do
      ^boolean_type ->
        boolean_type

      t1 when is_atom(t1) and is_atom(t1) ->
        boolean_type

      _ ->
        raise TypeError.raise_error(line, function, t1, boolean_type)
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

      {t1, t2} when is_atom(t1) and is_atom(t2) ->
        integer_type

      _ ->
        compatible?(function, t1, t2, integer_type, line)
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
        compatible?(function, t1, t2, boolean_type, line)
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
        compatible?(function, t1, t2, boolean_type, line)
    end
  end

  def get_function_type(function, t1, t2, line) when function in [:concat, :subtract] do
    string_type = get_type_string()
    list_type = get_type_list()

    case {t1, t2} do
      {^list_type, _} ->
        list_type

      {^string_type, ^string_type} ->
        string_type

      {^string_type, t2} when is_atom(t2) ->
        string_type

      _ ->
        try do
          compatible?(function, t1, t2, string_type, line)
        rescue
          TypeError ->
            case split_list_and_types(t1) do
              {enum, _} ->
                if is_list?(enum) do
                  list_type
                else
                  TypeError.raise_error(line, function, t1, t2, string_type)
                end

              false ->
                TypeError.raise_error(line, function, t1, t2, string_type)
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

      # Caso de dos indices o más seguidos
      {^integer_type, ^integer_type} ->
        var_type

      {^string_type, ^string_type} ->
        var_type

      {_, ^map_type} ->
        raise TypeError.raise_index_map_error(var_type)

      {_, ^string_type} ->
        raise TypeError.raise_index_error(var_type)

      {_, ^list_type} ->
        raise TypeError.raise_index_error(var_type)
    end
  end

  # En el caso de que en una operación haya un enumerado indexado
  # tenemos que comprobar los posibles tipos del enumerado
  defp compatible?(function, t1, t2, type, line) do
    t1_enum? = is_list(t1)

    t2_enum? = is_list(t2)

    compatible =
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

    if compatible do
      type
    else
      raise TypeError.raise_error(line, function, t1, t2, type)
    end
  end
end
