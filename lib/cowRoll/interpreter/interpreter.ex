defmodule Interpreter do
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
    {_, token, _, _, _, _} = Parser.parse(input)
    eval(token)
  end

  def eval({:number, number}), do: number

  def eval({:boolean, bool}), do: bool

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

  def eval({:divi, left_expression, right_expression}),
    do: div(eval(left_expression), eval(right_expression))

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
