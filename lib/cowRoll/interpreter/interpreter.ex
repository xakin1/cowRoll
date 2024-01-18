defmodule Interpreter do
  use Parser
  use DiceRoller

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

  defp delete_VarMap do
    :ets.delete(:var_map)
  end

  defp create_VarMap do
    # Comprobamos si existe
    case :lists.member(:var_map, :ets.all()) do
      false ->
        :ets.new(:var_map, [:named_table, read_concurrency: true, write_concurrency: true])

      true ->
        # La tabla ya existe, no hacemos nada
        :ok
    end
  end

  defp update_variable(var_name, value) when is_tuple(value) do
    case search_variable(var_name) do
      false ->
        result_eval = eval(value)
        insert_variable(var_name, result_eval)
        result_eval

      _ ->
        result_eval = eval(value)
        :ets.update_element(:var_map, var_name, {2, result_eval})
        result_eval
    end
  end

  defp update_variable(var_name, value) do
    case search_variable(var_name) do
      false ->
        insert_variable(var_name, value)
        value

      _ ->
        :ets.update_element(:var_map, var_name, {2, value})
        value
    end
  end

  defp insert_variable(var_name, value) do
    :ets.insert(:var_map, {var_name, value})
  end

  defp search_variable(var_name) do
    try do
      :ets.lookup_element(:var_map, var_name, 2)
    rescue
      _ -> false
    end
  end

  @spec eval_input(any()) :: any()
  def eval_input(input) do
    create_VarMap()
    {:ok, list_sentences} = Parser.parse(input)
    result = eval_tuple(list_sentences)
    delete_VarMap()
    result
  end

  defp eval_tuple(tuple) do
    case tuple do
      {first_element, second_element} when is_tuple(first_element) ->
        eval(first_element)
        eval_tuple(second_element)

      _ ->
        eval(tuple)
    end
  end

  defp eval_list(list_of_numbers) do
    case list_of_numbers do
      {first_element, second_element} when is_tuple(second_element) ->
        [eval(first_element), eval_list(second_element)]

      _ ->
        [eval(list_of_numbers)]
    end
  end

  defp eval({:number, number}), do: number

  defp eval({:boolean, bool}), do: bool

  defp eval({:string, string}) do
    case String.match?(string, ~r/^'.*'$/) do
      true -> String.trim(string, "'")
      false -> String.trim(string, "\"")
    end
  end

  defp eval({:not_defined, unknow}), do: throw({:error, unknow <> " is not defined"})

  defp eval({:var, variable}) do
    case search_variable(variable) do
      false -> throw({:error, "Variable '#{variable}' is not defined"})
      value -> value
    end
  end

  defp eval({:dice, dice}) do
    case(roll_dice(dice)) do
      {:ok, dice} -> dice
      {:error, error} -> throw({:error, error})
    end
  end

  defp eval({:negative, expresion}), do: -eval(expresion)

  defp eval({:not_operation, expresion}), do: not eval(expresion)

  defp eval({:list_of_number, list_of_numbers}) do
    case list_of_numbers do
      {first_element, second_element} when is_tuple(first_element) ->
        List.flatten([eval(first_element), eval_list(second_element)])

      _ ->
        [eval(list_of_numbers)]
    end
  end

  defp eval({:assignment, {_, var_name}, value}) do
    update_variable(var_name, value)
  end

  defp eval({:concat, left_expression, right_expression}),
    do: eval(left_expression) <> eval(right_expression)

  defp eval({:plus, left_expression, right_expression}),
    do: eval(left_expression) + eval(right_expression)

  defp eval({:minus, left_expression, right_expression}),
    do: eval(left_expression) - eval(right_expression)

  defp eval({:stric_more, left_expression, right_expression}),
    do: eval(left_expression) > eval(right_expression)

  defp eval({:more_equal, left_expression, right_expression}),
    do: eval(left_expression) >= eval(right_expression)

  defp eval({:stric_less, left_expression, right_expression}),
    do: eval(left_expression) < eval(right_expression)

  defp eval({:less_equal, left_expression, right_expression}),
    do: eval(left_expression) <= eval(right_expression)

  defp eval({:equal, left_expression, right_expression}),
    do: eval(left_expression) == eval(right_expression)

  defp eval({:not_equal, left_expression, right_expression}),
    do: eval(left_expression) != eval(right_expression)

  defp eval({:and_operation, left_expression, right_expression}),
    do: eval(left_expression) and eval(right_expression)

  defp eval({:or_operation, left_expression, right_expression}),
    do: eval(left_expression) or eval(right_expression)

  defp eval({:mult, left_expression, right_expression}),
    do: eval(left_expression) * eval(right_expression)

  defp eval({:divi, left_expression, right_expression}) do
    try do
      dividend = eval(left_expression)
      divider = eval(right_expression)

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

  defp eval({:round_div, left_expression, right_expression}) do
    try do
      dividend = eval(left_expression)
      divisor = eval(right_expression)

      case {dividend, divisor} do
        {_, 0} ->
          {:error, "Error: division by 0"}

        {dividend, divisor} ->
          result =
            div(dividend, divisor) + (1 - div(Integer.mod(dividend, divisor), divisor))

          result
      end
    catch
      {:error, error} -> {:error, error}
      _ -> {:error, "Aritmetic error: Unknow error"}
    end
  end

  defp eval({:mod, left_expression, right_expression}),
    do: Integer.mod(eval(left_expression), eval(right_expression))

  defp eval({:pow, left_expression, right_expression}),
    do: Integer.pow(eval(left_expression), eval(right_expression))

  defp eval({:range, range}) do
    try do
      case range do
        {:list_of_number, _} ->
          eval(range)

        {:var, _} ->
          eval(range)

        {first, last} ->
          {eval(first), eval(last)}

        element ->
          eval(element)
      end
    rescue
      error -> throw(error)
    end
  end

  defp eval({:for_loop, {:var, var_name}, range, expresion}) do
    try do
      case eval(range) do
        {first, last} ->
          for(x <- first..last) do
            update_variable(var_name, x)
            eval(expresion)
          end

        variable ->
          for(x <- variable) do
            update_variable(var_name, x)
            eval(expresion)
          end
      end
    rescue
      error -> throw(error)
    end
  end

  defp eval({:else, code}),
    do: eval(code)

  defp eval({:if_then_else, condition, then_expression, else_expression}) do
    if eval(condition) do
      eval(then_expression)
    else
      eval(else_expression)
    end
  end
end
