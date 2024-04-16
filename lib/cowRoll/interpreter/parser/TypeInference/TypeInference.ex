defmodule TypeInference do
  import TypesUtils
  import NestedIndexFinder
  import ListUtils
  import Compatibility
  import TypeExtractor

  @types [:number, :string, :boolean, :list, :map]
  @basic_type [:number, :string, :boolean]
  @complex_type [:list, :map]
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

  def infer(expression) do
    infer_expression(expression, %{})
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
    var_type = get_type_from_constraints(variable, constraints)

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
    enum_type = get_type_from_constraints(enum_name, constraints)

    case value do
      {function, value, _line} when function in @types ->
        {get_type(value), constraints}

      {:name, variable, _line} ->
        # Verificar si la variable ya existe en las restricciones
        var_type = get_type_from_constraints(variable, constraints)

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
        var_type = get_type_from_constraints(variable, constraints)

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

      {:assignment_function, {:function_name, {:name, _, line}}, {:parameters, parameters},
       {:function_code, function_code}} ->
        infer_expression(
          {:assignment_function, {:function_name, {:name, var, line}}, {:parameters, parameters},
           {:function_code, function_code}},
          constraints
        )

      expression ->
        # Verificar si la variable ya existe en las restricciones
        {var_type, constraints} = infer_expression(expression, constraints)

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
         {:assignment_function, {:function_name, {:name, function_name, _}},
          {:parameters, parameters}, {:function_code, function_code}},
         constraints
       ) do
    {_type, param_constraints} =
      case parameters do
        nil -> {nil, %{}}
        parameters -> infer_expression(parameters, %{})
      end

    constraints_with_params =
      Map.put(constraints, function_name <> "_parameters", param_constraints)

    # Agregar la función y su tipo a las restricciones
    {function_type, constraints} = infer_expression(function_code, constraints_with_params)

    constraints_with_function = Map.put(constraints, function_name, function_type)

    # Inferir el tipo de la función
    {_type, constraints_with_function} =
      infer_expression(function_code, constraints_with_function)

    # Tomando solo las llaves de map1 que están presentes en map2
    relevant_keys_map2 = Map.take(constraints_with_function, Map.keys(param_constraints))

    # Haciendo el merge, esta vez sin necesidad de una función de resolución
    updated_map = Map.merge(param_constraints, relevant_keys_map2)

    constraints_with_function =
      Map.put(constraints_with_function, function_name <> "_parameters", updated_map)

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

    var_type =
      case var_type do
        ^integer ->
          integer

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
         {:call_function, {:name, function_name, line}, {:parameters, parameters}},
         constraints
       ) do
    # Obtener el tipo de la función de las restricciones
    # Aquí puede ser o que la función no exista o que esté importada en un modulo como el elixir
    # caso en el que no podríamos inferir el tipo -> Podríamos dar un warning o nada y dejarlo en tiempo de ejecución
    function_type = get_type_from_constraints(function_name, constraints)

    # TODO: Hay que revisar que los tipos de los parámetros son correctos
    # Inferir el tipo de los parámetros
    # Lógica para determinar el tipo de retorno de la función
    parameter_types = get_parameter_types(parameters)

    get_parameter_type(parameter_types, constraints, function_name, line)
    {function_type, constraints}
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
      # Caso de que sea una lista o mapa
      {first, _} when is_atom(first) ->
        infer_expression(range, contraints)

      # Caso de que sea una variable
      {first, _, _} when is_atom(first) ->
        infer_expression(range, contraints)

      # Estamos en el caso de x..y donde x e y tienen que ser integers
      {first, last} ->
        {t1, new_constraints} =
          infer_range_type(first, contraints)

        {t2, new_constraints} = infer_range_type(last, new_constraints)

        {get_function_type(:range, t1, t2, get_line(first)), new_constraints}
    end
  end

  defp get_parameter_types(parameters) do
    case get_parameter_types_aux(parameters, %{}) do
      parameter_types when is_list(parameter_types) -> parameter_types
      parameter_types -> [parameter_types]
    end
  end

  defp get_parameter_types_aux(parameters, constraints) do
    case parameters do
      # Si no hay parámetros, devolvemos un mapa vacío
      nil ->
        []

      # caso genérico
      {head, _, _} when is_atom(head) ->
        {type, _} = infer_expression(parameters, constraints)
        type

      {head, tail} ->
        {type, constraint} = infer_expression(head, constraints)
        [type | [get_parameter_types_aux(tail, constraint)]]

      # Otros casos no manejados
      _ ->
        raise TypeError, message: "Unsupported parameters type"
    end
  end

  defp check_index_type(index, enum_type, constraints) do
    {var_type, _var_constraints} = infer_expression(index, constraints)

    case split_list_and_types(enum_type) do
      {enum, _element_types} ->
        get_index_type(var_type, enum)

      false ->
        nil
    end
  end

  defp get_type_from_constraints(variable, constraints) do
    case Map.get(constraints, variable) do
      nil -> fresh_type()
      existing_type -> existing_type
    end
  end

  defp get_var_name({:name, var_name, _line}), do: var_name
  defp get_line({_, _, line}), do: line

  defp infer_range_type(element, contraints) do
    integer = get_type_integer()

    case infer_expression(element, contraints) do
      {var_type, new_constraints} when is_atom(var_type) ->
        new_constraints = Map.put(new_constraints, get_var_name(element), integer)
        {var_type, new_constraints}

      {var_type, new_constraints} ->
        {var_type, new_constraints}
    end
  end
end
