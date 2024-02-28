defmodule SyntaxAnalyzer do
  def analyze(tokens) do
    analyze_aux(tokens, %{
      open_parenthesis: 0,
      close_parenthesis: 0,
      open_curly_bracket: 0,
      close_curly_bracket: 0,
      open_blocks: 0,
      close_blocks: 0,
      open_quotes: 0,
      close_quotes: 0,
      left_missing_parenthesis: [],
      right_missing_parenthesis: [],
      left_missing_curly_bracket: [],
      right_missing_curly_bracket: [],
      left_missing_quotes: [],
      right_missing_quotes: [],
      start_missing_blocks: [],
      end_missing_blocks: []
    })
  end

  defp analyze_aux([], records) do
    process_analyze(records)
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

  defp analyze_aux(
         [{:def_function, simbol, linea}, {:name, function_name, _line} | rest],
         records
       ) do
    records_updated =
      Map.update!(records, :open_blocks, &(&1 + 1))
      |> Map.update!(:start_missing_blocks, &[{linea, "#{simbol} #{function_name}"} | &1])

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux([{:end, linea} | rest], records) do
    open_blocks = Map.get(records, :open_blocks, 0)
    close_blocks = Map.get(records, :close_blocks, 0)

    new_records =
      if open_blocks > close_blocks do
        Map.update!(records, :close_blocks, &(&1 + 1))
      else
        Map.update!(records, :close_blocks, &(&1 + 1))
        |> Map.update!(:end_missing_blocks, &[{linea, "end"} | &1])
      end

    analyze_aux(rest, new_records)
  end

  defp analyze_aux([{:")", linea} | rest], records) do
    open_parenthesis = Map.get(records, :open_parenthesis, 0)
    close_parenthesis = Map.get(records, :close_parenthesis, 0)

    new_records =
      if open_parenthesis > close_parenthesis do
        Map.update!(records, :close_parenthesis, &(&1 + 1))
      else
        Map.update!(records, :close_parenthesis, &(&1 + 1))
        |> Map.update!(:right_missing_parenthesis, &[{linea, "("} | &1])
      end

    analyze_aux(rest, new_records)
  end

  defp analyze_aux([{:"(", linea} | rest], records) do
    records_updated =
      Map.update!(records, :open_parenthesis, &(&1 + 1))
      |> Map.update!(:left_missing_parenthesis, &[{linea, ")"} | &1])

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux([{:"}", linea} | rest], records) do
    open_parenthesis = Map.get(records, :open_curly_bracket, 0)
    close_parenthesis = Map.get(records, :close_curly_bracket, 0)

    new_records =
      if open_parenthesis > close_parenthesis do
        Map.update!(records, :close_curly_bracket, &(&1 + 1))
      else
        Map.update!(records, :close_curly_bracket, &(&1 + 1))
        |> Map.update!(:right_missing_curly_bracket, &[{linea, "{"} | &1])
      end

    analyze_aux(rest, new_records)
  end

  defp analyze_aux([{:"{", linea} | rest], records) do
    records_updated =
      Map.update!(records, :open_curly_bracket, &(&1 + 1))
      |> Map.update!(:left_missing_curly_bracket, &[{linea, "}"} | &1])

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux([_ | rest], records) do
    analyze_aux(rest, records)
  end

  defp process_analyze(records) do
    open_parenthesis = Map.get(records, :open_parenthesis, 0)
    close_parenthesis = Map.get(records, :close_parenthesis, 0)

    right_missing_parenthesis = Map.get(records, :right_missing_parenthesis, [])
    left_missing_parenthesis = Map.get(records, :left_missing_parenthesis, [])

    open_blocks = Map.get(records, :open_blocks, 0)
    close_blocks = Map.get(records, :close_blocks, 0)

    start_missing_blocks = Map.get(records, :start_missing_blocks, [])
    end_missing_blocks = Map.get(records, :end_missing_blocks, [])

    open_curly_bracket = Map.get(records, :open_curly_bracket, 0)
    close_curly_bracket = Map.get(records, :close_curly_bracket, 0)

    right_missing_curly_bracket = Map.get(records, :right_missing_curly_bracket, [])
    left_missing_curly_bracket = Map.get(records, :left_missing_curly_bracket, [])

    check_open_close(
      {open_parenthesis, close_parenthesis, right_missing_parenthesis, left_missing_parenthesis}
    )

    check_open_close(
      {open_curly_bracket, close_curly_bracket, right_missing_curly_bracket,
       left_missing_curly_bracket}
    )

    if open_blocks == close_blocks do
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

  defp check_open_close({open, close, right_missing, left_missing}) do
    if open == close do
      :ok
    else
      case {right_missing, left_missing} do
        {[], _} ->
          # Si estamos aquí, significa que falta un ')'
          {line, simbol} = hd(left_missing)
          raise RuntimeError, message: "Error: Missing '#{simbol}' on line #{line}"

        {_, []} ->
          # Si estamos aquí, significa que falta un (
          {line, simbol} = hd(right_missing)

          raise RuntimeError, message: "Error: Missing '#{simbol}' on line #{line}"

        _ ->
          # En este caso, tanto hay bloques de inicio como de fin faltantes, no podemos determinar cuál es el error principal.
          {line, simbol} = hd(left_missing)
          raise RuntimeError, message: "Error: Missing '#{simbol}' on line #{line}"
      end
    end
  end
end
