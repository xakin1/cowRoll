defmodule Interpreter do
  use Parser

  @spec eval_input(any()) :: any()
  def eval_input(input) do
    {:ok, ast} = Parser.parse(input)
    eval(ast)
  end

  defp eval(ast) when is_list(ast), do: Enum.reduce(ast, {0, 0}, &eval/2)
  defp eval({{:move, :forward}, {:number, x}}, {h, depth}), do: {h + x, depth}
  defp eval({{:move, :down}, {:number, x}}, {h, depth}), do: {h, depth + x}
  defp eval({{:move, :up}, {:number, x}}, {h, depth}), do: {h, depth - x}
end
