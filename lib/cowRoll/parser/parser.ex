defmodule Parser do
  @doc """
  Attempts to tokenize an input string to start_tag, end_tag, and char
  """
  def parse(input) do
    {:ok, tokens, _} = input |> to_charlist |> :lexical_analysis.string()
    :grammar_spec.parse(tokens)
  end
end
