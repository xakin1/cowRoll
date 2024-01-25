defmodule Interpreter do
  use Parser
  use DiceRoller
  import TreeNode

  defp bad_type(function_name, type) do
    msg = "Error, in " <> function_name <> " operation both factors must be " <> type
    msg
  end

  defp bad_type_unitary(function_name, type) do
    msg = "Error, in " <> function_name <> " operation the factor must be " <> type
    msg
  end

  @type expr_ast ::
          {:mult, expr_ast, expr_ast}
          | {:divi, expr_ast, expr_ast}
          | {:plus, expr_ast, expr_ast}
          | {:minus, expr_ast, expr_ast}
          | {:negative, expr_ast}
          | {:not_operation, expr_ast}
          | {:assignment, expr_ast, expr_ast}
          | {:stric_more, expr_ast, expr_ast}
          | {:more_equal, expr_ast, expr_ast}
          | {:stric_less, expr_ast, expr_ast}
          | {:less_equal, expr_ast, expr_ast}
          | {:equal, expr_ast, expr_ast}
          | {:not_equal, expr_ast, expr_ast}
          | {:and_operation, expr_ast, expr_ast}
          | {:or_operation, expr_ast, expr_ast}
          | {:round_div, expr_ast, expr_ast}
          | {:mod, expr_ast, expr_ast}
          | {:pow, expr_ast, expr_ast}
          | {:number, number}
          | {:negative_number, number}
          | {:boolean, boolean}
          | {:string, String.t()}
          | {:not_defined, String.t()}
          | {:dice, expr_ast, expr_ast}
          | {:negative, expr_ast}
          | {:name, String.t()}
          | {:list, expr_ast}
          | {:assignment, {:name, String.t()}, expr_ast}
          | {:concat, expr_ast, expr_ast}
          | {:range, expr_ast}
          | {:for_loop, {:name, String.t()}, expr_ast, expr_ast}
          | {:if_then_else, expr_ast, expr_ast, expr_ast}
          | {:assignment_function, {:function_name, String.t()}, {:parameters, expr_ast},
             {:function_code, expr_ast}}
          | {:call_function, String.t(), {:parameters, expr_ast}}
          | {:call_function, String.t()}

  @type aterm ::
          {:number, any(), integer()}
          | {:dice, charlist()}
          | {:not_defined, charlist()}
          | expr_ast

  @spec eval_input(any()) :: any()
  def eval_input(input) do
    # Creamos un arbol que va a tener el scope de las variables
    node = create_tree()

    {:ok, list_sentences} = Parser.parse(input)
    result = eval_block(node.id, list_sentences)

    delete_tree()
    result
  end

  # Necesario para analizar más de una sentencia
  defp eval_block(scope, tuple) do
    case tuple do
      {first_element, second_element} when is_tuple(first_element) ->
        eval(scope, first_element)
        eval_block(scope, second_element)

      _ ->
        eval(scope, tuple)
    end
  end

  # Necesario para construir una lista
  defp eval_list(scope, list) do
    case list do
      {first_element, second_element} when is_tuple(second_element) ->
        [eval(scope, first_element), eval_list(scope, second_element)]

      _ ->
        [eval(scope, list)]
    end
  end

  defp eval(_, {:number, number}), do: number

  defp eval(_, {:boolean, bool}), do: bool

  defp eval(_, {:string, string}) do
    case String.match?(string, ~r/^'.*'$/) do
      true -> String.trim(string, "'")
      false -> String.trim(string, "\"")
    end
  end

  defp eval(scope, {:negative, expresion}) do
    case eval(scope, expresion) do
      value when is_integer(value) -> -value
      _ -> throw({:error, bad_type_unitary("-", "number")})
    end
  end

  defp eval(scope, {:not_operation, expresion}) do
    case eval(scope, expresion) do
      value when is_boolean(value) -> not value
      _ -> throw({:error, bad_type_unitary("not", "boolean")})
    end
  end

  defp eval(scope, {:name, variable}) do
    case get_variable_from_scope(scope, variable) do
      false -> throw({:error, "Variable '#{variable}' is not defined"})
      value -> value
    end
  end

  defp eval(scope, {:list, list}) do
    case list do
      {first_element, second_element} when is_tuple(first_element) ->
        List.flatten([eval(scope, first_element), eval_list(scope, second_element)])

      nil ->
        []

      _ ->
        [eval(scope, list)]
    end
  end

  defp eval(scope, {:assignment, {_, var_name}, value}) do
    add_variable_to_scope(scope, var_name, eval(scope, value))
  end

  defp eval(scope, {:concat, left_expression, right_expression}),
    do:
      do_binary_operation_with_check(
        [eval(scope, left_expression), eval(scope, right_expression)],
        &is_bitstring/1,
        &<>/2,
        bad_type("++", "string")
      )

  defp eval(scope, {:dice, number_of_dices, number_of_faces}),
    do:
      do_binary_operation_with_check(
        [eval(scope, number_of_dices), eval(scope, number_of_faces)],
        &is_integer/1,
        &roll_dices/2,
        bad_type("dice", "numbers")
      )

  defp eval(scope, {:plus, left_expression, right_expression}),
    do:
      do_binary_operation_with_check(
        [eval(scope, left_expression), eval(scope, right_expression)],
        &is_integer/1,
        &+/2,
        bad_type("+", "numbers")
      )

  defp eval(scope, {:minus, left_expression, right_expression}),
    do:
      do_binary_operation_with_check(
        [eval(scope, left_expression), eval(scope, right_expression)],
        &is_integer/1,
        &-/2,
        bad_type("-", "numbers")
      )

  defp eval(scope, {:mult, left_expression, right_expression}),
    do:
      do_binary_operation_with_check(
        [eval(scope, left_expression), eval(scope, right_expression)],
        &is_integer/1,
        &*/2,
        bad_type("*", "numbers")
      )

  defp eval(scope, {:divi, left_expression, right_expression}) do
    try do
      dividend = eval(scope, left_expression)
      divider = eval(scope, right_expression)

      case {dividend, divider} do
        {_, 0} ->
          {:error, "Error: division by 0"}

        {dividend, divider} ->
          do_binary_operation_with_check(
            [dividend, divider],
            &is_integer/1,
            &div/2,
            bad_type("/", "numbers")
          )
      end
    catch
      {:error, error} -> throw({:error, error})
    end
  end

  defp eval(scope, {:round_div, left_expression, right_expression}) do
    try do
      dividend = eval(scope, left_expression)
      divisor = eval(scope, right_expression)

      case {dividend, divisor} do
        {_, 0} ->
          {:error, "Error: division by 0"}

        {dividend, divisor} ->
          check_type([dividend, divisor], &is_integer/1, bad_type("//", "numbers"))
          result = div(dividend, divisor) + ceil(rem(dividend, divisor) / divisor)

          result
      end
    catch
      {:error, error} -> throw({:error, error})
    end
  end

  defp eval(scope, {:mod, left_expression, right_expression}) do
    try do
      dividend = eval(scope, left_expression)
      module = eval(scope, right_expression)

      case {dividend, module} do
        {_, 0} ->
          throw({:error, "Error: division by 0"})

        {dividend, module} ->
          do_binary_operation_with_check(
            [dividend, module],
            &is_integer/1,
            &Integer.mod/2,
            bad_type("%", "numbers")
          )
      end
    catch
      {:error, error} -> throw({:error, error})
    end
  end

  defp eval(scope, {:pow, left_expression, right_expression}),
    do:
      do_binary_operation_with_check(
        [eval(scope, left_expression), eval(scope, right_expression)],
        &is_integer/1,
        &Integer.pow/2,
        bad_type("^", "numbers")
      )

  defp eval(scope, {:stric_more, left_expression, right_expression}),
    do: eval(scope, left_expression) > eval(scope, right_expression)

  defp eval(scope, {:more_equal, left_expression, right_expression}),
    do: eval(scope, left_expression) >= eval(scope, right_expression)

  defp eval(scope, {:stric_less, left_expression, right_expression}),
    do: eval(scope, left_expression) < eval(scope, right_expression)

  defp eval(scope, {:less_equal, left_expression, right_expression}),
    do: eval(scope, left_expression) <= eval(scope, right_expression)

  defp eval(scope, {:equal, left_expression, right_expression}),
    do: eval(scope, left_expression) == eval(scope, right_expression)

  defp eval(scope, {:not_equal, left_expression, right_expression}),
    do: eval(scope, left_expression) != eval(scope, right_expression)

  defp eval(scope, {:and_operation, left_expression, right_expression}),
    do:
      do_binary_operation_with_check(
        [eval(scope, left_expression), eval(scope, right_expression)],
        &is_boolean/1,
        &and/2,
        bad_type("and", "boolean")
      )

  defp eval(scope, {:or_operation, left_expression, right_expression}),
    do:
      do_binary_operation_with_check(
        [eval(scope, left_expression), eval(scope, right_expression)],
        &is_boolean/1,
        &or/2,
        bad_type("or", "boolean")
      )

  defp eval(scope, {:range, range}) do
    case range do
      {:list, _} ->
        eval(scope, range)

      {:name, _} ->
        eval(scope, range)

      {first, last} ->
        {eval(scope, first), eval(scope, last)}
    end
  end

  defp eval(scope, {:for_loop, {:name, var_name}, range, expresion}) do
    scope = add_scope(scope, :for_loop)

    result =
      case eval(scope, range) do
        {first, last} ->
          for(x <- first..last) do
            add_variable_to_scope(scope, var_name, x)
            eval(scope, expresion)
          end

        variable ->
          for(x <- variable) do
            add_variable_to_scope(scope, var_name, x)
            eval(scope, expresion)
          end
      end

    remove_scope(:for_loop)
    result
  end

  defp eval(scope, {:if_then_else, condition, then_expression, else_expression}) do
    node = add_scope(scope, :for_loop)
    condition = eval(scope, condition)

    result =
      case condition do
        condition when is_boolean(condition) ->
          if condition do
            eval_block(node, then_expression)
          else
            eval_block(node, else_expression)
          end

        _ ->
          throw({:error, bad_type_unitary("condition", "boolean")})
      end

    remove_scope(:for_loop)
    result
  end

  defp eval(
         _,
         {:assignment_function, {:function_name, function_name}, {:parameters, parameters},
          {:function_code, function_code}}
       ) do
    add_fuction_to_scope(function_name, parameters, function_code)
  end

  defp eval(
         scope,
         {:call_function, function_name, {:parameters, parameters}}
       ) do
    {parameters_to_replace, code} = get_fuction_from_scope(function_name)
    node = add_scope(scope, function_name)

    case initialize_function(scope, parameters_to_replace, parameters) do
      {:error, error} ->
        throw({:error, error})

      _ ->
        result = eval_block(node, code)
        remove_scope(function_name)
        result
    end
  end

  defp initialize_function(scope, parameters_to_replace, parameters) do
    case {parameters_to_replace, parameters} do
      {{parameter_to_replace_head, tail}, {parameter_head, _}}
      when is_tuple(parameter_to_replace_head) and not is_tuple(parameter_head) ->
        eval(scope, {:assignment, parameter_to_replace_head, parameters})
        initialize_function(scope, tail, {})

      {{parameter_to_replace_head, _}, {parameter_head, tail}}
      when not is_tuple(parameter_to_replace_head) and is_tuple(parameter_head) ->
        eval(scope, {:assignment, parameters_to_replace, parameter_head})
        initialize_function(scope, {}, tail)

      {{parameter_to_replace_head, tail_to_replace}, {parameter_head, tail}}
      when is_tuple(parameter_to_replace_head) and is_tuple(parameter_head) ->
        eval(scope, {:assignment, parameter_to_replace_head, parameter_head})
        initialize_function(scope, tail_to_replace, tail)

      {{parameter_to_replace_head, _}, {parameter_head, _}}
      when not is_tuple(parameter_to_replace_head) and not is_tuple(parameter_head) ->
        eval(scope, {:assignment, parameters_to_replace, parameters})
        initialize_function(scope, {}, {})

      {{}, {}} ->
        :ok

      {nil, nil} ->
        :ok

      _ ->
        {:error, "bad number of parameters"}
    end
  end

  defp do_binary_operation_with_check(
         factors,
         is_x_type,
         operation,
         error
       ) do
    check_type(factors, is_x_type, error)

    case Enum.reduce(factors, &operation.(&2, &1)) do
      value -> value
    end
  end

  defp check_type(factors, is_x_type, error) do
    is_correct_type =
      Enum.reduce(factors, true, fn factor, acc ->
        acc and is_x_type.(factor)
      end)

    if !is_correct_type do
      throw({:error, error})
    end
  end
end
