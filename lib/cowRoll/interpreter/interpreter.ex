defmodule Interpreter do
  use Parser
  use DiceRoller
  import TreeNode

  @type expr_ast ::
          {:mult, aterm, aterm}
          | {:divi, aterm, aterm}
          | {:plus, aterm, aterm}
          | {:minus, aterm, aterm}
          | {:negative, aterm}
          | {:not_operation, aterm}
          | {:assignment, aterm, aterm}
          | {:stric_more, aterm, aterm}
          | {:more_equal, aterm, aterm}
          | {:stric_less, aterm, aterm}
          | {:less_equal, aterm, aterm}
          | {:equal, aterm, aterm}
          | {:not_equal, aterm, aterm}
          | {:and_operation, aterm, aterm}
          | {:or_operation, aterm, aterm}
          | {:round_div, aterm, aterm}
          | {:mod, aterm, aterm}
          | {:pow, aterm, aterm}
          | aterm

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

  defp eval(_, {:not_defined, unknow}),
    do: throw({:error, unknow <> " is not defined"})

  defp eval(_, {:dice, dice}) do
    case(roll_dice(dice)) do
      {:ok, dice} -> dice
      {:error, error} -> throw({:error, error})
    end
  end

  defp eval(scope, {:negative, expresion}), do: -eval(scope, expresion)

  defp eval(scope, {:not_operation, expresion}), do: not eval(scope, expresion)

  defp eval(scope, {:var, variable}) do
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
    do: eval(scope, left_expression) <> eval(scope, right_expression)

  defp eval(scope, {:plus, left_expression, right_expression}),
    do: eval(scope, left_expression) + eval(scope, right_expression)

  defp eval(scope, {:minus, left_expression, right_expression}),
    do: eval(scope, left_expression) - eval(scope, right_expression)

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
    do: eval(scope, left_expression) and eval(scope, right_expression)

  defp eval(scope, {:or_operation, left_expression, right_expression}),
    do: eval(scope, left_expression) or eval(scope, right_expression)

  defp eval(scope, {:mult, left_expression, right_expression}),
    do: eval(scope, left_expression) * eval(scope, right_expression)

  defp eval(scope, {:divi, left_expression, right_expression}) do
    try do
      dividend = eval(scope, left_expression)
      divider = eval(scope, right_expression)

      case {dividend, divider} do
        {_, 0} ->
          {:error, "Error: division by 0"}

        {dividend, divider} ->
          div(dividend, divider)
      end
    catch
      {:error, error} -> {:error, error}
      _ -> {:error, "Aritmetic error: Unknow error"}
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
          result = div(dividend, divisor) + ceil(rem(dividend, divisor) / divisor)

          result
      end
    catch
      {:error, error} -> {:error, error}
      _ -> {:error, "Aritmetic error: Unknow error"}
    end
  end

  defp eval(scope, {:mod, left_expression, right_expression}) do
    try do
      dividend = eval(scope, left_expression)
      module = eval(scope, right_expression)

      case {dividend, module} do
        {_, 0} ->
          {:error, "Error: division by 0"}

        {dividend, module} ->
          result =
            Integer.mod(dividend, module)

          result
      end
    catch
      {:error, error} -> {:error, error}
      _ -> {:error, "Aritmetic error: Unknow error"}
    end
  end

  defp eval(scope, {:pow, left_expression, right_expression}) do
    base = eval(scope, left_expression)
    exponent = eval(scope, right_expression)
    Integer.pow(base, exponent)
  end

  defp eval(scope, {:range, range}) do
    try do
      case range do
        {:list, _} ->
          eval(scope, range)

        {:var, _} ->
          eval(scope, range)

        {first, last} ->
          {eval(scope, first), eval(scope, last)}

        element ->
          eval(scope, element)
      end
    rescue
      error -> throw(error)
    end
  end

  defp eval(scope, {:for_loop, {:var, var_name}, range, expresion}) do
    try do
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
    rescue
      error -> throw(error)
    end
  end

  defp eval(scope, {:else, code}),
    do: eval(scope, code)

  defp eval(scope, {:if_then_else, condition, then_expression, else_expression}) do
    node = add_scope(scope, :for_loop)

    result =
      if eval(scope, condition) do
        eval_block(node, then_expression)
      else
        eval_block(node, else_expression)
      end

    remove_scope(:for_loop)
    result
  end

  defp eval(
         _,
         {:assignament_function, {:function_name, function_name}, {:parameters, parameters},
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
        result = eval(node, code)
        remove_scope(function_name)
        result
    end
  end

  defp eval(
         scope,
         {:call_function, function_name}
       ) do
    {_, code} = get_fuction_from_scope(function_name)
    node = add_scope(scope, function_name)
    result = eval(node, code)
    remove_scope(function_name)
    result
  end

  defp initialize_function(scope, parameters_to_replace, parameters) do
    case {parameters_to_replace, parameters} do
      {{parameter_to_replace_head, _}, {parameter_head, _}}
      when not is_tuple(parameter_to_replace_head) or not is_tuple(parameter_head) ->
        eval(scope, {:assignment, parameters_to_replace, parameters})
        initialize_function(scope, {}, {})

      {{parameter_to_replace_head, tail_to_replace}, {parameter_head, tail}}
      when is_tuple(parameter_to_replace_head) and is_tuple(parameter_head) ->
        eval(scope, {:assignment, parameter_to_replace_head, parameter_head})
        initialize_function(scope, tail_to_replace, tail)

      {{}, {}} ->
        :ok

      _ ->
        {:error, "bad number of parameters"}
    end
  end
end
