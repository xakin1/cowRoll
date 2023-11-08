defmodule Interpreter do
  use Parser
  use DiceRoller

  @spec eval_input(any()) :: any()
  def eval_input(input) do
    {:ok, ast} = Parser.parse(input)
    eval(ast)
  end

  # defp eval(ast) when is_list(ast), do: Enum.reduce(ast, {0, 0}, &eval/2)
  defp eval({:dice, dice}), do: {roll_dice(dice)}
end
