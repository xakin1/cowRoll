defmodule SyntaxAnalyzer do
  def analyze(tokens) do
    analyze_aux(tokens, %{
      open_parenthesis: 0,
      close_parenthesis: 0,
      open_blocks: 0,
      close_blocks: 0,
      left_missing_parenthesis: [],
      right_missing_parenthesis: [],
      start_missing_blocks: [],
      end_missing_blocks: []
    })
  end

  defp analyze_aux([], records) do
    process_analyze(records)
  end

  defp analyze_aux([{:"(", linea} | rest], records) do
    records_updated =
      Map.update!(records, :open_parenthesis, &(&1 + 1))
      |> Map.update!(:left_missing_parenthesis, &[{linea, "("} | &1])

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux([{:if, linea} | rest], records) do
    records_updated =
      Map.update!(records, :open_blocks, &(&1 + 1))
      |> Map.update!(:start_missing_blocks, &[{linea, "if"} | &1])

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux([{:for, linea} | rest], records) do
    records_updated =
      Map.update!(records, :open_blocks, &(&1 + 1))
      |> Map.update!(:start_missing_blocks, &[{linea, "for"} | &1])

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux([{:end, linea} | rest], records) do
    open_b = Map.get(records, :open_blocks, 0)
    close_b = Map.get(records, :close_blocks, 0)

    new_records =
      if open_b > close_b do
        Map.update!(records, :close_blocks, &(&1 + 1))
      else
        Map.update!(records, :close_blocks, &(&1 + 1))
        |> Map.update!(:end_missing_blocks, &[{linea, "end"} | &1])
      end

    analyze_aux(rest, new_records)
  end

  defp analyze_aux([{:")", linea} | rest], records) do
    open_p = Map.get(records, :open_parenthesis, 0)
    close_p = Map.get(records, :close_parenthesis, 0)

    new_records =
      if open_p > close_p do
        Map.update!(records, :close_parenthesis, &(&1 + 1))
      else
        Map.update!(records, :close_parenthesis, &(&1 + 1))
        |> Map.update!(:right_missing_parenthesis, &[{linea, ")"} | &1])
      end

    analyze_aux(rest, new_records)
  end

  defp analyze_aux([_ | rest], records) do
    analyze_aux(rest, records)
  end

  defp process_analyze(records) do
    open_p = Map.get(records, :open_parenthesis, 0)
    close_p = Map.get(records, :close_parenthesis, 0)

    open_b = Map.get(records, :open_blocks, 0)
    close_b = Map.get(records, :close_blocks, 0)

    right_missing_parenthesis = Map.get(records, :right_missing_parenthesis, [])
    left_missing_parenthesis = Map.get(records, :left_missing_parenthesis, [])

    start_missing_blocks = Map.get(records, :start_missing_blocks, [])
    end_missing_blocks = Map.get(records, :end_missing_blocks, [])

    if open_p == close_p do
      :ok
    else
      case {right_missing_parenthesis, left_missing_parenthesis} do
        {[], _} ->
          # Si estamos aquí, significa que falta un ')'
          {line, _} = hd(left_missing_parenthesis)
          raise RuntimeError, message: "Error: Missing ')' on line #{line}"

        {_, []} ->
          # Si estamos aquí, significa que falta un (
          {line, _} = hd(right_missing_parenthesis)

          raise RuntimeError, message: "Error: Missing '(' on line #{line}"

        _ ->
          # En este caso, tanto hay bloques de inicio como de fin faltantes, no podemos determinar cuál es el error principal.
          {line, _} = hd(left_missing_parenthesis)
          raise RuntimeError, message: "Error: Missing '(' on line #{line}"
      end
    end

    if open_b == close_b do
      :ok
    else
      case {start_missing_blocks, end_missing_blocks} do
        {[], _} ->
          # Si estamos aquí, significa que falta un 'end'
          {line, simbol} = hd(end_missing_blocks)
          raise RuntimeError, message: "Error: Unexpected '#{simbol}' on line #{line}"

        {_, []} ->
          # Si estamos aquí, significa que falta un inicio correspondiente (como 'do', 'if', 'for', etc.)
          {line, simbol} = hd(start_missing_blocks)

          raise RuntimeError,
            message: "Error: Missing 'end' for '#{simbol}' on line #{line}"

        _ ->
          # En este caso, tanto hay bloques de inicio como de fin faltantes, no podemos determinar cuál es el error principal.
          {line, simbol} = hd(end_missing_blocks)
          raise RuntimeError, message: "Error: Missing 'end' for '#{simbol}' on line #{line}"
      end
    end
  end
end
