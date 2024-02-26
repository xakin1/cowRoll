defmodule Parser do
  defmacro __using__(_opts) do
    quote do
      import Parser
    end
  end

  import SyntaxAnalyzer
  @spec parse(any()) :: {:error, any()} | {:ok, tuple()}
  @doc """
  Attempts to tokenize an input string to start_tag, end_tag, and char
  """
  def parse(input) do
    result = input |> to_charlist |> :lexical_analysis.string()

    case result do
      {:ok, tokens, _} ->
        case analyze(tokens) do
          :ok ->
            case :grammar_spec.parse(tokens) do
              {:error, error} ->
                throw({:error, error})

              input_parsed ->
                input_parsed
            end
        end
    end
  end
end
