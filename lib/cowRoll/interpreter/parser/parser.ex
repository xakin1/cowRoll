defmodule Parser do
  defmacro __using__(_opts) do
    quote do
      import Parser
    end
  end

  @spec parse(any()) :: {:error, any()} | {:ok, tuple()}
  @doc """
  Attempts to tokenize an input string to start_tag, end_tag, and char
  """
  def parse(input) do
    {:ok, tokens, _} = input |> to_charlist |> :lexical_analysis.string()

    case :grammar_spec.parse(tokens) do
      {:error, {_, :grammar_spec, [~c"syntax error before: ", []]}} ->
        throw({:error, "missing statement"})

      {:error, {_, :grammar_spec, [~c"syntax error before: ", ~c"')'"]}} ->
        throw({:error, "missing left parenthesis"})

      {:ok, {:error, error}} ->
        throw({:error, to_string(error)})

      input_parsed ->
        input_parsed
    end
  end
end
