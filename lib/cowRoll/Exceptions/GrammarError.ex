defmodule GrammarError do
  defexception message: "Wrong grammar"

  @spec raise_error_missing_line(any(), any()) :: none()
  def raise_error_missing_line(simbol, line) do
    message =
      "Error: Missing '#{simbol}' on line #{line}"

    raise __MODULE__, message: message
  end

  @spec raise_error_unexpected_end(any(), any()) :: none()
  def raise_error_unexpected_end(simbol, line) do
    message =
      "Error: Unexpected '#{simbol}' on line #{line}"

    raise __MODULE__, message: message
  end

  def raise_error_missing_end(simbol, line) do
    message =
      "Error: Missing 'end' for '#{simbol}' on line #{line}"

    raise __MODULE__, message: message
  end

  def raise_error_bad_assignment(line) do
    message =
      "Error at line #{line}: Assignment can only be done to variables."

    raise __MODULE__, message: message
  end

  def raise_error_bad_expression(line) do
    message =
      "Error at line #{line}: Expression can only be done with variables or constants."

    raise __MODULE__, message: message
  end

  def raise_error_missing_comma(line) do
    message =
      "Error at line #{line}: missing ','"

    raise __MODULE__, message: message
  end
end
