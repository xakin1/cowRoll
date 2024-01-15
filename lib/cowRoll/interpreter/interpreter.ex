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
    :ets.new(:var_map, [:named_table, read_concurrency: true, write_concurrency: true])
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

  def eval({:number, number}), do: number

  def eval({:boolean, bool}), do: bool

  def eval({:string, string}), do: string

  def eval({:not_defined, unknow}), do: throw({:error, unknow <> " is not defined"})

  def eval({:var, variable}) do
    case search_variable(variable) do
      false -> throw({:error, "Variable '#{variable}' is not defined"})
      value -> value
    end
  end

  def eval({:dice, dice}) do
    case(roll_dice(dice)) do
      {:ok, dice} -> dice
      {:error, error} -> throw({:error, error})
    end
  end

  def eval({:negative, expresion}), do: -eval(expresion)

  def eval({:not_operation, expresion}), do: not eval(expresion)

  def eval({:list_of_number, list_of_numbers}) do
    case list_of_numbers do
      {first_element, second_element} when is_tuple(first_element) ->
        List.flatten([eval(first_element), eval_list(second_element)])

      _ ->
        [eval(list_of_numbers)]
    end
  end

  def eval({:assignment, {_, var_name}, value}) do
    update_variable(var_name, value)
  end

  def eval({:plus, left_expression, right_expression}),
    do: eval(left_expression) + eval(right_expression)

  def eval({:minus, left_expression, right_expression}),
    do: eval(left_expression) - eval(right_expression)

  def eval({:stric_more, left_expression, right_expression}),
    do: eval(left_expression) > eval(right_expression)

  def eval({:more_equal, left_expression, right_expression}),
    do: eval(left_expression) >= eval(right_expression)

  def eval({:stric_less, left_expression, right_expression}),
    do: eval(left_expression) < eval(right_expression)

  def eval({:less_equal, left_expression, right_expression}),
    do: eval(left_expression) <= eval(right_expression)

  def eval({:equal, left_expression, right_expression}),
    do: eval(left_expression) == eval(right_expression)

  def eval({:not_equal, left_expression, right_expression}),
    do: eval(left_expression) != eval(right_expression)

  def eval({:and_operation, left_expression, right_expression}),
    do: eval(left_expression) and eval(right_expression)

  def eval({:or_operation, left_expression, right_expression}),
    do: eval(left_expression) or eval(right_expression)

  def eval({:mult, left_expression, right_expression}),
    do: eval(left_expression) * eval(right_expression)

  def eval({:divi, left_expression, right_expression}) do
    try do
      dividend = eval(left_expression)
      divider = eval(right_expression)

      case {dividend, divider} do
        {_, 0} ->
          {:error, "Error: division by 0"}

        {dividend, _} when not is_integer(dividend) ->
          {:error, "Error: dividend must be an integer"}

        {_, divider} when not is_integer(divider) ->
          {:error, "Error: divider must be an integer"}

        {dividend, divider} ->
          div(dividend, divider)
      end
    catch
      {:error, error} -> {:error, error}
      _ -> {:error, "Aritmetic error: Unknow error"}
    end
  end

  def eval({:round_div, left_expression, right_expression}) do
    evaluated_left_expression = eval(left_expression)
    evaluated_right_expression = eval(right_expression)

    div(evaluated_left_expression, evaluated_right_expression) +
      rem(evaluated_left_expression, evaluated_right_expression)
  end

  def eval({:mod, left_expression, right_expression}),
    do: Integer.mod(eval(left_expression), eval(right_expression))

  def eval({:pow, left_expression, right_expression}),
    do: Integer.pow(eval(left_expression), eval(right_expression))

  def eval({:range, range}) do
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

  def eval({:for_loop, {:var, var_name}, range, expresion}) do
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

  def eval({:else, code}),
    do: eval(code)

  def eval({:if_then_else, condition, then_expression, else_expression}) do
    if eval(condition) do
      eval(then_expression)
    else
      eval(else_expression)
    end
  end
end
