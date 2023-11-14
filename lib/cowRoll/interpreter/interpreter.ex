defmodule Interpreter do
  use Parser
  use DiceRoller

  @type expr_ast ::
          {:mult, aterm, aterm}
          | {:divi, aterm, aterm}
          | {:plus, aterm, aterm}
          | {:minus, aterm, aterm}
          | aterm

  @type aterm ::
          {:number, any(), integer()}
          | {:dice, charlist()}
          | expr_ast

  @spec eval_input(any()) :: any()
  def eval_input(input) do
    {:ok, ast} = Parser.parse(input)
    eval(ast)
  end

  def eval({:number, number}), do: number

  def eval({:boolean, bool}), do: bool

  def eval({:string, string}), do: string

  def eval({:not_defined, unknow}), do: throw({:error, unknow <> " is not defined"})

  def eval({:dice, dice}) do
    case(roll_dice(dice)) do
      {:ok, dice} -> dice
      {:error, error} -> throw({:error, error})
    end
  end

  def eval({:negative, expresion}), do: -eval(expresion)

  def eval({:not_operation, expresion}), do: not eval(expresion)

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

  def eval({:else, code}),
    do: eval(code)

  def eval({:if_then_else, condition, then_expression}) do
    case then_expression do
      {:else, expression, else_expression} ->
        if eval(condition) do
          eval(expression)
        else
          eval(else_expression)
        end

      _ ->
        if eval(condition), do: eval(then_expression)
    end
  end
end
