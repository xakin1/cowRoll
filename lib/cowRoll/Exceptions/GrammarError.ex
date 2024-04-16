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
end
