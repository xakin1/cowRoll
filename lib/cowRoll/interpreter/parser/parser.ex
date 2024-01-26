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
    result = input |> to_charlist |> :lexical_analysis.string()

    try do
      case result do
        {:ok, tokens, _} ->
          case :grammar_spec.parse(tokens) do
            {:error, error} ->
              throw({:error, error})

            input_parsed ->
              input_parsed
          end
      end
    catch
      {:error, {line, :grammar_spec, [~c"syntax error before: ", []]}} ->
        throw(
          {:error,
           "Error de sintaxis en la línea #{line}: Falta un paréntesis o hay un problema de sintaxis."}
        )

      {:error, {line, :grammar_spec, [~c"syntax error before: ", ~c"')'"]}} ->
        throw(
          {:error,
           "Error de sintaxis en la línea #{line}: Falta un paréntesis o hay un problema de sintaxis."}
        )

      {:error, {line, :grammar_spec, [~c"syntax error before: ", ~c"'<-'"]}} ->
        throw(
          {:error,
           "Error de sintaxis en la línea #{line}: Falta un for o hay un problema de sintaxis."}
        )

      {:error, {line, :grammar_spec, _}} ->
        throw({:error, "Error de sintaxis en la línea #{line}"})
    end
  end
end
