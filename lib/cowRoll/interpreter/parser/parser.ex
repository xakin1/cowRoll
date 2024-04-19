defmodule Parser do
  import SyntaxAnalyzer
  import TypeInference
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
              {:ok, input_parsed} ->
                infer(input_parsed)
                {:ok, input_parsed}

              {:error, {line, :grammar_spec, _}} ->
                raise GrammarError, message: "Unexpected error at line #{line}."
            end
        end
    end
  end
end
