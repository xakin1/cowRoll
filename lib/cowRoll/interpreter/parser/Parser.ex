defmodule CowRoll.Parser do
  import SyntaxAnalyzer
  import TypeInference
  import GrammarError

  def init(code) do
    parse(code)
  end

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
                raise raise_unexpector_error(line)
            end
        end

      _ ->
        raise RuntimeError, message: "Unexpected error ."
    end
  end
end
