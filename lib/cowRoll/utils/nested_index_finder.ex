defmodule NestedIndexFinder do
  def find_index_pattern({:index, {number, nested}}) do
    nested_index = find_index_pattern(nested)
    list_of_index = [number] ++ nested_index
    list_of_index
  end

  def find_index_pattern(var_or_name) do
    [var_or_name]
  end

  defp get_index({:index, {var_or_name1, var_or_name2}}) do
    get_index(var_or_name1) ++ get_index(var_or_name2)
  end

  defp get_index(var_or_name) do
    [var_or_name]
  end

  def find_name_pattern({:index, {number_or_var, {:name, var_name, line}}}) do
    indexes = get_index(number_or_var)
    {{:name, var_name, line}, indexes}
  end

  @spec find_levels(any()) :: non_neg_integer()
  def find_levels({:index, next_index}) do
    1 + find_levels(next_index)
  end

  def find_levels({{:index, next_index}, _}) do
    1 + find_levels(next_index)
  end

  def find_levels(_) do
    0
  end
end
