defmodule TypeError do
  defexception message: "Incompatible types"

  @spec raise_error(any(), any(), any(), any()) :: none()
  def raise_error(line, function, type1, expected_type) do
    message =
      "Error at line #{line} in '#{get_function(function)}' operation, Incompatible type: #{type1} was found but #{expected_type} was expected"

    raise __MODULE__, message: message
  end

  @spec raise_error(any(), any(), any(), any(), any()) :: none()
  def raise_error(line, function, type1, type2, expected_type) do
    message =
      "Error at line #{line} in '#{get_function(function)}' operation, Incompatible types: #{type1}, #{type2} were found but #{expected_type}, #{expected_type} were expected"

    raise __MODULE__, message: message
  end

  def raise_index_error(expected_type) do
    message =
      "The index must be an Integer but #{expected_type} was found"

    raise __MODULE__, message: message
  end

  def raise_index_map_error(expected_type) do
    message =
      "The index must be an Integer or a String but #{expected_type} was found"

    raise __MODULE__, message: message
  end

  defp get_function(function) do
    case function do
      :mult -> "*"
      :divi -> "/"
      :plus -> "+"
      :minus -> "-"
      :negative -> "-"
      :assignment -> "assignment"
      :stric_more -> ">"
      :more_equal -> ">="
      :stric_less -> "<"
      :less_equal -> "<="
      :equal -> "=="
      :not_equal -> "!="
      :not_operation -> "not"
      :and_operation -> "and"
      :or_operation -> "or"
      :round_div -> "//"
      :mod -> "%"
      :pow -> "^"
      :concat -> "++"
      :subtract -> "--"
      _ -> function
    end
  end
end
