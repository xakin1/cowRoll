defmodule SyntaxAnalyzer do
  def analyze(tokens) do
    count_parenthesis(tokens)
    count_blocks(tokens)
  end

  defp count_parenthesis(tokens) do
    count_parenthesis(tokens, 0, 0, [], [])
  end

  defp count_parenthesis([], open, close, left_missing, right_missing) do
    process_parenthesis({open, close, left_missing, right_missing})
  end

  defp count_parenthesis([{:"(", linea} | rest], open, close, left_missing, right_missing) do
    count_parenthesis(rest, open + 1, close, left_missing, right_missing ++ [{linea, "("}])
  end

  defp count_parenthesis([{:")", linea} | rest], open, close, left_missing, right_missing) do
    if open > close do
      count_parenthesis(rest, open, close + 1, left_missing, right_missing)
    else
      count_parenthesis(rest, open, close + 1, left_missing ++ [{linea, ")"}], right_missing)
    end
  end

  defp count_parenthesis([_ | rest], open, close, left_missing, right_missing) do
    count_parenthesis(rest, open, close, left_missing, right_missing)
  end

  defp process_parenthesis({open, close, left_missing, right_missing}) do
    if open == close do
      :ok
    else
      case {left_missing, right_missing} do
        {[], _} ->
          # Si estamos aquí, significa que falta un ')'
          {line, _} = hd(right_missing)
          raise RuntimeError, message: "Error: Missing ')' on line #{line}"

        {_, []} ->
          # Si estamos aquí, significa que falta un (
          {line, _} = hd(left_missing)

          raise RuntimeError, message: "Error: Missing '(' on line #{line}"

        _ ->
          # En este caso, tanto hay bloques de inicio como de fin faltantes, no podemos determinar cuál es el error principal.
          {line, _} = hd(left_missing)
          raise RuntimeError, message: "Error: Missing '(' on line #{line}"
      end
    end
  end

  defp count_blocks(tokens) do
    count_blocks(tokens, 0, 0, [], [])
  end

  defp count_blocks([{:if, linea} | rest], starts, ends, start_missing, end_missing) do
    count_blocks(rest, starts + 1, ends, start_missing, end_missing ++ [{linea, "if"}])
  end

  defp count_blocks([{:for, linea} | rest], starts, ends, start_missing, end_missing) do
    count_blocks(rest, starts + 1, ends, start_missing, end_missing ++ [{linea, "for"}])
  end

  defp count_blocks([{:end, linea} | rest], starts, ends, start_missing, end_missing) do
    if starts > ends do
      count_blocks(rest, starts, ends + 1, start_missing, end_missing)
    else
      count_blocks(rest, starts, ends + 1, start_missing ++ [{linea, "end"}], end_missing)
    end
  end

  defp count_blocks([_ | rest], starts, ends, start_missing, end_missing) do
    count_blocks(rest, starts, ends, start_missing, end_missing)
  end

  defp count_blocks([], starts, ends, start_missing, end_missing) do
    process_blocks({starts, ends, start_missing, end_missing})
  end

  defp process_blocks({starts, ends, start_missing, end_missing}) do
    if starts == ends do
      :ok
    else
      case {start_missing, end_missing} do
        {[], _} ->
          # Si estamos aquí, significa que falta un 'end'
          {line, simbol} = hd(end_missing)
          raise RuntimeError, message: "Error: Missing 'end' for '#{simbol}' on line #{line}"

        {_, []} ->
          # Si estamos aquí, significa que falta un inicio correspondiente (como 'do', 'if', 'for', etc.)
          {line, _} = hd(start_missing)

          raise RuntimeError,
            message: "Error: Unexpected 'end' on line #{line}"

        _ ->
          # En este caso, tanto hay bloques de inicio como de fin faltantes, no podemos determinar cuál es el error principal.
          {line, simbol} = hd(end_missing)
          raise RuntimeError, message: "Error: Missing 'end' for '#{simbol}' on line #{line}"
      end
    end
  end
end
