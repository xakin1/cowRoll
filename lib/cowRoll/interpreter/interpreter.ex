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

  @spec eval({:dice, any()} | {:number, any()}) :: any()
  def eval({:number, number}), do: number

  def eval({:dice, dice}) do
    case(roll_dice(dice)) do
      {:ok, dice} -> dice
      {:error, error} -> throw({:error, error})
    end
  end

  def eval({:mult, expresion_izquierda, expresion_derecha}),
    do: eval(expresion_izquierda) * eval(expresion_derecha)

  def eval({:plus, expresion_izquierda, expresion_derecha}),
    do: eval(expresion_izquierda) + eval(expresion_derecha)

  def eval({:minus, expresion_izquierda, expresion_derecha}),
    do: eval(expresion_izquierda) - eval(expresion_derecha)

  def eval({:divi, expresion_izquierda, expresion_derecha}),
    do: div(eval(expresion_izquierda), eval(expresion_derecha))
end
