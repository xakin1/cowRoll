defmodule NestedIndexFinder do
  def find_name_pattern({:index, {{:name, var_name}, number_or_var}}) do
    {{:name, var_name}, [number_or_var]}
  end

  def find_name_pattern({:index, {nested, number_or_var}}) do
    {var_name, nested_index} = find_name_pattern(nested)
    list_of_index = nested_index ++ [number_or_var]
    {var_name, list_of_index}
  end

  def find_name_pattern(_) do
    {:error, "Patrón no reconocido"}
  end
end
