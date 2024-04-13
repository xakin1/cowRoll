defmodule TypeInference do
  import TypesUtils
  import NestedIndexFinder
  import ListUtils

  @types [:number, :string, :boolean, :list, :map]
  @basic_type [:number, :string, :boolean]
  @complex_type [:list, :map]
  @operadores [
    :mult,
    :divi,
    :plus,
    :minus,
    :assignment,
    :stric_more,
    :more_equal,
    :stric_less,
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

  def infer(expression) do
    {type, constraints} = infer_expression(expression, %{})
    {type, unify_constraints(constraints)}
  end

  defp infer_expression({basic_type, value, _line}, constraints)
       when basic_type in @basic_type do
    {get_type(value), constraints}
  end

  defp infer_expression({{basic_type, value, line}, next_expr}, constraints)
       when basic_type in @basic_type do
    {_var_type, constraints} =
      infer_expression({basic_type, value, line}, constraints)

    infer_expression(next_expr, constraints)
  end

  defp infer_expression({enum, expression}, constraints)
       when enum in @complex_type do
    type = extract_enum_types(enum, expression)

    {type, constraints}
  end

  defp infer_expression({{complex_type, line}, next_expr}, constraints)
       when complex_type in @complex_type do
    {_var_type, constraints} =
      infer_expression({complex_type, line}, constraints)

    infer_expression(next_expr, constraints)
  end

  defp infer_expression({:name, variable, _line}, constraints) do
    # Verificar si la variable ya existe en las restricciones
    var_type =
      case Map.get(constraints, variable) do
        nil -> fresh_type()
        existing_type -> existing_type
      end

    # Agrega restricciones que relacionan las variables originales con la nueva variable de tipo.
    # Para el caso de z = y, donde y es una variable {t1, [%{z => t1, y => t1}]}
    new_constraints = %{variable => var_type}
    constraints = Map.merge(new_constraints, constraints)

    # Devuelve la nueva variable de tipo y las restricciones actualizadas
    {var_type, constraints}
  end

  defp infer_expression({{:name, variable, line}, next_expr}, constraints) do
    {_var_type, constraints} =
      infer_expression({:name, variable, line}, constraints)

    infer_expression(next_expr, constraints)
  end

  defp infer_expression(
         {:assignment, {:index, {_index, {:name, enum_name, _line}}}, value},
         constraints
       ) do
    enum_type =
      case Map.get(constraints, enum_name) do
        nil -> fresh_type()
        existing_type -> existing_type
      end

    case value do
      {function, value, _line} when function in @types ->
        {get_type(value), constraints}

      {:name, variable, _line} ->
        # Verificar si la variable ya existe en las restricciones
        var_type =
          case Map.get(constraints, variable) do
            nil -> fresh_type()
            existing_type -> existing_type
          end

        # Agrega restricciones que relacionan las variables originales con la nueva variable de tipo.
        # Para el caso de z = y, donde y es una variable {t1, [%{z => t1, y => t1}]}
        new_constraints = %{enum_name => "#{enum_type} | #{var_type}", variable => var_type}
        constraints = Map.merge(new_constraints, constraints)

        # Devuelve la nueva variable de tipo y las restricciones actualizadas
        {var_type, constraints}

      expression ->
        # Verificar si la variable ya existe en las restricciones
        {var_type, _constraint} = infer_expression(expression, constraints)

        new_constraints = %{enum_name => "#{enum_type} | #{var_type}"}
        constraints = Map.merge(new_constraints, constraints)

        # Devuelve la nueva variable de tipo y las restricciones actualizadas
        {var_type, constraints}
    end
  end

  defp infer_expression({:assignment, {:name, var, _line}, value}, constraints) do
    case value do
      {basic_type, value, _line} when basic_type in @basic_type ->
        constraints_with_var = Map.put(constraints, var, get_type(value))
        {get_type(value), constraints_with_var}

      {:name, variable, _line} ->
        # Verificar si la variable ya existe en las restricciones
        var_type =
          case Map.get(constraints, variable) do
            nil -> fresh_type()
            existing_type -> existing_type
          end

        # Agrega restricciones que relacionan las variables originales con la nueva variable de tipo.
        # Para el caso de z = y, donde y es una variable {t1, [%{z => t1, y => t1}]}
        new_constraints = %{var => var_type, variable => var_type}
        constraints = Map.merge(new_constraints, constraints)

        # Devuelve la nueva variable de tipo y las restricciones actualizadas
        {var_type, constraints}

      {:index, {index, enum}} ->
        # Verificar si la variable ya existe en las restricciones
        {var_type, constraint} = infer_expression(enum, constraints)

        levels = find_levels(value)

        {enum_type, enum_types} = split_list_and_types(var_type, levels)

        check_index_type(index, enum_type, constraint)

        new_constraints = %{var => enum_types}
        constraints = Map.merge(new_constraints, constraints)

        # Devuelve la nueva variable de tipo y las restricciones actualizadas
        {enum_types, constraints}

      expression ->
        # Verificar si la variable ya existe en las restricciones
        {var_type, _constraint} = infer_expression(expression, constraints)

        new_constraints = %{var => var_type}
        constraints = Map.merge(new_constraints, constraints)

        # Devuelve la nueva variable de tipo y las restricciones actualizadas
        {var_type, constraints}
    end
  end

  defp infer_expression({{:assignment, var, value}, next_expr}, constraints) do
    {_var_type, constraints} =
      infer_expression({:assignment, var, value}, constraints)

    infer_expression(next_expr, constraints)
  end

  defp infer_expression(
         {function, {left_expr, right_expr}, {_symbol, line}},
         constraints
       )
       when function in @operadores do
    {left_type, constraints} = infer_expression(left_expr, constraints)
    {right_type, constraints} = infer_expression(right_expr, constraints)
    {get_function_type(function, left_type, right_type, line), constraints}
  end

  defp infer_expression(
         {{function, {left_expr, right_expr}, {symbol, line}}, next_expression},
         constraints
       )
       when function in @operadores do
    {_, constraints} =
      infer_expression(
        {function, {left_expr, right_expr}, {symbol, line}},
        constraints
      )

    infer_expression(next_expression, constraints)
  end

  defp infer_expression({:index, {index_value, enum_value}}, constraints) do
    # Comprobamos que el índice es de un tipo correcto
    {enum_type, enum_constraints} = infer_expression(enum_value, constraints)
    index_type = check_index_type(index_value, enum_type, constraints)
    integer = get_type_integer()

    case {enum_type, index_type} do
      {"List of" <> _, ^integer} ->
        levels = find_levels({:index, {index_value, enum_value}})
        types = extract_types(enum_type, levels)
        # Si el indice es de un tipo correcto simplemente devolvemos el tipo de la lista
        {types, enum_constraints}

      {"Map of" <> _, ^integer} ->
        levels = find_levels({:index, {index_value, enum_value}})
        types = extract_types(enum_type, levels)
        # Si el indice es de un tipo correcto simplemente devolvemos el tipo de la lista
        {types, enum_constraints}

      # Caso de varios indices sobre un array
      _ ->
        {enum_type, enum_constraints}
    end
  end

  defp infer_expression(
         {unary_function, expr_ast, {_symbol, line}},
         constraints
       )
       when unary_function in [
              :negative,
              :not_operation
            ] do
    {expr_type, constraints} = infer_expression(expr_ast, constraints)
    {get_function_type(unary_function, expr_type, line), constraints}
  end

  defp infer_expression(
         {{unary_function, expr_ast, {symbol, line}}, next_expression},
         constraints
       )
       when unary_function in [
              :negative,
              :not_operation
            ] do
    {_, constraints} =
      infer_expression(
        {unary_function, {expr_ast}, {symbol, line}},
        constraints
      )

    infer_expression(next_expression, constraints)
  end

  defp infer_expression(
         {:assignment_function, {:function_name, {:name, function_name, _}}, {:parameters, _},
          {:function_code, function_code}},
         constraints
       ) do
    # Agregar la función y su tipo a las restricciones
    {function_type, constraints} = infer_expression(function_code, constraints)

    constraints_with_function = Map.put(constraints, function_name, function_type)

    # Inferir el tipo de la función
    {_type, constraints_with_function} =
      infer_expression(function_code, constraints_with_function)

    # Devolver el tipo de la función y las restricciones actualizadas
    {function_type, constraints_with_function}
  end

  defp infer_expression(
         {{:assignment_function, {:function_name, {:name, function_name, line}},
           {:parameters, parameters}, {:function_code, function_code}}, next_expression},
         constraints
       ) do
    {_, constraints} =
      infer_expression(
        {:assignment_function, {:function_name, {:name, function_name, line}},
         {:parameters, parameters}, {:function_code, function_code}},
        constraints
      )

    infer_expression(next_expression, constraints)
  end

  defp infer_expression(
         {:if_then_else, condition, then_expr, else_expr, {_simbol, line}},
         constraints
       ) do
    # Inferir el tipo de la condición
    {condition_type, constraints} = infer_expression(condition, constraints)

    boolean = get_type_boolean()
    # Verificar que la condición sea de tipo booleano
    case condition_type do
      ^boolean ->
        # Inferir el tipo de la expresión then
        {then_type, constraints} = infer_expression(then_expr, constraints)
        t0 = fresh_type()

        # Puede no existir una clausula else
        constraints =
          if(else_expr != nil) do
            # Inferir el tipo de la expresión else
            {else_type, constraints} = infer_expression(else_expr, constraints)
            t1 = fresh_type()

            Map.merge(%{t0 => then_type, t1 => else_type}, constraints)
          else
            t0 = fresh_type()

            Map.merge(%{t0 => then_type}, constraints)
          end

        # Devolver el tipo de la expresión then y las restricciones actualizadas
        {then_type, constraints}

      _ ->
        # La condición no es de tipo booleano, lanzar un error
        raise TypeError.raise_error(line, "condition", condition_type, boolean)
    end
  end

  defp infer_expression(
         {{:if_then_else, condition, then_expression, else_expression, {simbol, line}},
          next_expr},
         constraints
       ) do
    {_var_type, constraints} =
      infer_expression(
        {:if_then_else, condition, then_expression, else_expression, {simbol, line}},
        constraints
      )

    infer_expression(next_expr, constraints)
  end

  defp infer_expression(
         {{:for_loop, {:name, var_name, line}, range, expresion}, next_expr},
         constraints
       ) do
    {_var_type, constraints} =
      infer_expression(
        {:for_loop, {:name, var_name, line}, range, expresion},
        constraints
      )

    infer_expression(next_expr, constraints)
  end

  defp infer_expression(
         {:for_loop, {:name, var_name, _line}, range, expresion},
         constraints
       ) do
    {var_type, new_constraints} = infer_expression(range, constraints)
    integer = get_type_integer()
    string = get_type_string()

    var_type =
      case var_type do
        ^integer ->
          integer

        ^string ->
          string

        "List of " <> _ ->
          [TypesUtils.get_type_list(), String.trim_leading(var_type, "List of ")]

        "Map of " <> _ ->
          String.trim_leading(var_type, "Map of ")

        # Los tipos 'tX' se tratan como tipos base.
        _ ->
          var_type
      end

    var_constraints = %{var_name => var_type}
    constraints = Map.merge(new_constraints, constraints)
    constraints = Map.merge(var_constraints, constraints)
    infer_expression(expresion, constraints)
  end

  defp infer_expression(
         {:call_function, {:name, function_name, _line}, {:parameters, parameters}},
         constraints
       ) do
    # Obtener el tipo de la función de las restricciones
    function_type =
      case Map.get(constraints, function_name) do
        # Aquí puede ser o que la función no exista o que esté importada en un modulo como el elixir
        # caso en el que no podríamos inferir el tipo -> Podríamos dar un warning o nada y dejarlo en tiempo de ejecución
        nil -> fresh_type()
        existing_type -> existing_type
      end

    # Inferir el tipo de los parámetros
    # Lógica para determinar el tipo de retorno de la función
    parameter_types = get_parameter_types(parameters, constraints)
    {get_return_type(function_type, parameter_types), constraints}
  end

  defp infer_expression({{:range, range}, next_expr}, constraints) do
    {_var_type, constraints} =
      infer_expression(
        {:range, range},
        constraints
      )

    infer_expression(next_expr, constraints)
  end

  defp infer_expression({:range, range}, contraints) do
    case range do
      {first, _} when is_atom(first) ->
        infer_expression(range, contraints)

      {first, _, _} when is_atom(first) ->
        infer_expression(range, contraints)

      {first, last} ->
        {_var_type, new_constraints} = infer_expression(first, contraints)
        infer_expression(last, new_constraints)
    end
  end

  # TODO: Revisar esto
  defp get_return_type(function_type, parameter_types) do
    function_type
  end

  defp get_parameter_types(parameters, constraints) do
    case parameters do
      # Si no hay parámetros, devolvemos un mapa vacío
      nil ->
        %{}

      # Si hay parámetros y es una tupla, inferimos sus tipos
      {head, _, _} when is_atom(head) ->
        infer_expression(parameters, constraints)

      {_, tail} ->
        {_, constraint} = infer_expression(parameters, constraints)
        get_parameter_types(tail, constraint)

      # Otros casos no manejados
      _ ->
        raise TypeError, message: "Unsupported parameters type"
    end
  end

  defp get_function_type(function, t1, line)
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

  defp get_function_type(function, t1, line)
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

  defp get_function_type(function, t1, t2, line)
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
        compatible?(function, t1, t2, integer_type, line)
    end
  end

  defp get_function_type(function, t1, t2, line)
       when function in [:stric_more, :more_equal, :stric_less, :less_equal] do
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

      _ ->
        compatible?(function, t1, t2, boolean_type, line)
    end
  end

  defp get_function_type(function, t1, t2, line)
       when function in [:and_operation, :or_operation] do
    boolean_type = get_type_boolean()

    case {t1, t2} do
      {^boolean_type, ^boolean_type} ->
        boolean_type

      {t1, ^boolean_type} when is_atom(t1) ->
        boolean_type

      {^boolean_type, t2} when is_atom(t2) ->
        boolean_type

      _ ->
        compatible?(function, t1, t2, boolean_type, line)
    end
  end

  defp get_function_type(function, t1, t2, line) when function in [:concat, :subtract] do
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

  defp get_function_type(function, _t1, _t2, _line)
       when function in [:equal, :not_equal],
       do: get_type_boolean()

  def unify_constraints(constraints) do
    unify_constraints(constraints, %{})
  end

  # Caso base para unificar restricciones
  defp unify_constraints(%{}, substitution) do
    substitution
  end

  # Función privada para unificar restricciones
  defp unify_constraints(constraints, substitution) do
    # TODO: Revisar esto
    {{var, type}, remaining} = Map.pop(constraints, nil)

    new_substitution =
      case Map.get(substitution, var) do
        nil -> Map.put(substitution, var, type)
        existing_type -> unify(existing_type, type, substitution)
      end

    unify_constraints(remaining, new_substitution)
  end

  defp unify(t1, t2, substitution) when t1 == t2 do
    substitution
  end

  defp unify(t1, t2, substitution) when is_atom(t1) do
    Map.put(substitution, t1, t2)
  end

  defp unify(t1, t2, substitution) when is_atom(t2) do
    Map.put(substitution, t2, t1)
  end

  defp check_index_type(index, enum_type, constraints) do
    {var_type, _var_constraints} = infer_expression(index, constraints)

    case split_list_and_types(enum_type) do
      {enum, _element_types} ->
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

      false ->
        nil
    end
  end

  # Case simple types: integers, booleans...

  # For lists
  defp get_enum_types(
         {{function, {left_expr, right_expr}, {symbol, line}}, rest},
         types
       )
       when function in @operadores do
    {function_type, _} =
      infer_expression(
        {function, {left_expr, right_expr}, {symbol, line}},
        %{}
      )

    types = MapSet.put(types, function_type)

    get_enum_types(rest, types)
  end

  defp get_enum_types({function, {left_expr, right_expr}, {symbol, line}}, types)
       when function in @operadores do
    {function_type, _} =
      infer_expression(
        {function, {left_expr, right_expr}, {symbol, line}},
        %{}
      )

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
      infer_expression(
        {:if_then_else, condition, then_expression, else_expression, {function, line}},
        %{}
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
      infer_expression(
        {:if_then_else, condition, then_expression, else_expression, {function, line}},
        %{}
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
      infer_expression(
        {:if_then_else, condition, then_expression, else_expression, {function, line}},
        %{}
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
      infer_expression(
        {:if_then_else, condition, then_expression, else_expression, {function, line}},
        %{}
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
      infer_expression(
        {function, {left_expr, right_expr}, {symbol, line}},
        %{}
      )

    types = MapSet.put(types, function_type)

    get_map_types(rest, types)
  end

  defp get_map_types({_key, {function, {left_expr, right_expr}, {symbol, line}}}, types)
       when function in @operadores do
    {function_type, _} =
      infer_expression(
        {function, {left_expr, right_expr}, {symbol, line}},
        %{}
      )

    MapSet.put(types, function_type)
  end

  defp get_map_types({_key, {type, _value, _line}}, types) do
    MapSet.put(types, type)
  end

  defp get_map_types({{_key, {type, _value, _line}}, rest}, types) do
    types = MapSet.put(types, type)
    get_map_types(rest, types)
  end

  # Enum: tipo del enumerado
  # expression: tupla del enumerado
  defp extract_enum_types(enum, expression) do
    types_enum =
      case enum do
        :list -> get_enum_types(expression, MapSet.new())
        :map -> get_map_types(expression, MapSet.new())
      end

    # Convertimos los atomos en strings
    newTypes =
      Enum.map(types_enum, fn type ->
        case type do
          type when is_atom(type) -> get_type(type)
          _ -> type
        end
      end)

    case newTypes do
      [] ->
        "#{get_type(enum)} of #{fresh_type()}"

      _ ->
        "#{get_type(enum)} of #{Enum.join(newTypes, " | ")}"
    end
  end

  # En el caso de que en una operación haya un enumerado indexado
  # tenemos que comprobar los posibles tipos del enumerado
  defp compatible?(function, t1, t2, type, line) do
    t1_enum? = is_list(t1)

    t2_enum? = is_list(t2)

    error_message =
      "Error at line #{line} in '#{}' operation, Incompatible types: #{t1}, #{t2} was found but #{type}, #{type} was expected"

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
