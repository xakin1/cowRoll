defmodule Arrays do
  def set_element_at(list, indices, new_value) do
    set_element_at_aux(list, indices, new_value)
  end

  defp set_element_at_aux(list, [index | []], new_value) do
    List.replace_at(list, index, new_value)
  end

  defp set_element_at_aux(list, [index | rest], new_value) do
    element_to_update = Enum.at(list, index)
    List.replace_at(list, index, set_element_at_aux(element_to_update, rest, new_value))
  end
end
