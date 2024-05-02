defmodule Tuples do
  @spec count_tuples(tuple()) :: non_neg_integer()
  def count_tuples(tuple) when is_tuple(tuple) do
    count_tuples(tuple, 0)
  end

  def count_tuples(nil) do
    count_tuples({}, 0)
  end

  defp count_tuples({_, tail}, acc) do
    count_tuples(tail, acc + 1)
  end

  defp count_tuples({_, _, _}, acc) do
    count_tuples([], acc + 1)
  end

  defp count_tuples(_, acc) do
    acc
  end
end
