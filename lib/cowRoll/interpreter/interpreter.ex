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

  def eval({:dice, dice}) do
    case(roll_dice(dice)) do
      {:ok, dice} -> dice
      {:error, error} -> throw({:error, error})
    end
  end

  def eval({:negative, expresion}), do: -eval(expresion)

  def eval({:mult, left_expression, right_expression}),
    do: eval(left_expression) * eval(right_expression)

  def eval({:pow, left_expression, right_expression}),
    do: Integer.pow(eval(left_expression), eval(right_expression))

  def eval({:plus, left_expression, right_expression}),
    do: eval(left_expression) + eval(right_expression)

  def eval({:minus, left_expression, right_expression}),
    do: eval(left_expression) - eval(right_expression)

  def eval({:divi, left_expression, right_expression}),
    do: div(eval(left_expression), eval(right_expression))

  def eval({:mod, left_expression, right_expression}),
    do: Integer.mod(eval(left_expression), eval(right_expression))

  def eval({:round_div, left_expression, right_expression}) do
    evaluated_left_expression = eval(left_expression)
    evaluated_right_expression = eval(right_expression)

    div(evaluated_left_expression, evaluated_right_expression) +
      rem(evaluated_left_expression, evaluated_right_expression)
  end
end
