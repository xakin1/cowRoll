defmodule Exceptions.RuntimeError do
  defexception [message: "unknown error", line: nil]
  import Tuples


  @spec runtimeError_raise_error(any(), any(), any(), any()) :: none()
  def runtimeError_raise_error(function_name, line, parameters_to_replace, parameters) do
    message =
      "Error at line #{line}: bad number of parameters on #{function_name} expected #{count_tuples(parameters_to_replace)} but got #{count_tuples(parameters)}"

    raise __MODULE__, message: message, line: line
  end

  @spec runtimeError_raise_error(any(), any()) :: none()
  def runtimeError_raise_error(variable, line) do
    message = "Variable '#{variable}' is not defined on line #{line}"
    raise __MODULE__, message: message, line: line
  end
  def runtimeError_raise_error_function_missing(function_name, line) do
    message = "Error at line #{line}, Undefined function: '#{function_name}'"
    raise __MODULE__, message: message, line: line
  end
end
