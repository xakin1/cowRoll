defmodule SyntaxAnalyzer do
  import GrammarError

  @expressions_operators [
    :%,
    :^,
    :/,
    :*,
    :+,
    :==,
    :-,
    :++,
    :--,
    :"//",
    :!=,
    :>,
    :>=,
    :<=,
    :<,
    :or,
    :and
  ]

  @statement_operators [
    :for,
    :if,
    :def_function
  ]
  @errors %{
    open_parenthesis: 0,
    close_parenthesis: 0,
    open_curly_bracket: 0,
    close_curly_bracket: 0,
    open_bracket: 0,
    close_bracket: 0,
    open_blocks: 0,
    close_blocks: 0,
    open_quotes: 0,
    close_quotes: 0,
    left_missing_parenthesis: [],
    right_missing_parenthesis: [],
    left_missing_curly_bracket: [],
    right_missing_curly_bracket: [],
    left_missing_bracket: [],
    right_missing_bracket: [],
    left_missing_quotes: [],
    right_missing_quotes: [],
    start_missing_blocks: [],
    end_missing_blocks: [],
    bad_assignment: nil,
    invalid_expression: nil,
    missing_comma: nil
  }
  def analyze(tokens) do
    analyze_aux(tokens, @errors)
  end

  defp analyze_aux([], records) do
    process_analyze(records)
  end

  defp analyze_aux([{:name, _, _}, {:=, _line} | rest], records) do
    analyze_aux(rest, records)
  end

  defp analyze_aux([_, {:=, line} | rest], records) do
    records_updated =
      Map.update!(records, :bad_assignment, fn _ ->
        line
      end)

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux([_, {operator, line}, {statement, _} | rest], records)
       when statement in @statement_operators and operator in @expressions_operators do
    records_updated =
      Map.update!(records, :invalid_expression, fn _ ->
        line
      end)

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux([_, {:end, 1}, {operator, line} | rest], records)
       when operator in @expressions_operators do
    records_updated =
      Map.update!(records, :invalid_expression, fn _ ->
        line
      end)

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux(
         [{:name, _, _}, {:":", line}, _, {:name, _, _}, {:":", _} | rest],
         records
       ) do
    records_updated =
      Map.update!(records, :missing_comma, fn _ ->
        line
      end)

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux([{:if, line} | rest], records) do
    records_updated =
      Map.update!(records, :open_blocks, &(&1 + 1))
      |> Map.update!(:start_missing_blocks, &[{line, "if"} | &1])

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux([{:for, line} | rest], records) do
    records_updated =
      Map.update!(records, :open_blocks, &(&1 + 1))
      |> Map.update!(:start_missing_blocks, &[{line, "for"} | &1])

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux(
         [{:def_function, simbol, line}, {:name, function_name, _line} | rest],
         records
       ) do
    records_updated =
      Map.update!(records, :open_blocks, &(&1 + 1))
      |> Map.update!(:start_missing_blocks, &[{line, "#{simbol} #{function_name}"} | &1])

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux([{:end, line} | rest], records) do
    open_blocks = Map.get(records, :open_blocks, 0)
    close_blocks = Map.get(records, :close_blocks, 0)

    new_records =
      if open_blocks > close_blocks do
        Map.update!(records, :close_blocks, &(&1 + 1))
      else
        Map.update!(records, :close_blocks, &(&1 + 1))
        |> Map.update!(:end_missing_blocks, &[{line, "end"} | &1])
      end

    analyze_aux(rest, new_records)
  end

  defp analyze_aux([{:")", line} | rest], records) do
    open_parenthesis = Map.get(records, :open_parenthesis, 0)
    close_parenthesis = Map.get(records, :close_parenthesis, 0)

    new_records =
      if open_parenthesis > close_parenthesis do
        Map.update!(records, :close_parenthesis, &(&1 + 1))
      else
        Map.update!(records, :close_parenthesis, &(&1 + 1))
        |> Map.update!(:right_missing_parenthesis, &[{line, "("} | &1])
      end

    analyze_aux(rest, new_records)
  end

  defp analyze_aux([{:"(", line} | rest], records) do
    records_updated =
      Map.update!(records, :open_parenthesis, &(&1 + 1))
      |> Map.update!(:left_missing_parenthesis, &[{line, ")"} | &1])

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux([{:"}", line} | rest], records) do
    open_parenthesis = Map.get(records, :open_curly_bracket, 0)
    close_parenthesis = Map.get(records, :close_curly_bracket, 0)

    new_records =
      if open_parenthesis > close_parenthesis do
        Map.update!(records, :close_curly_bracket, &(&1 + 1))
      else
        Map.update!(records, :close_curly_bracket, &(&1 + 1))
        |> Map.update!(:right_missing_curly_bracket, &[{line, "{"} | &1])
      end

    analyze_aux(rest, new_records)
  end

  defp analyze_aux([{:"{", line} | rest], records) do
    records_updated =
      Map.update!(records, :open_curly_bracket, &(&1 + 1))
      |> Map.update!(:left_missing_curly_bracket, &[{line, "}"} | &1])

    analyze_aux(rest, records_updated)
  end

  defp analyze_aux([{:"]", line} | rest], records) do
    open_parenthesis = Map.get(records, :open_bracket, 0)
    close_parenthesis = Map.get(records, :close_bracket, 0)

    new_records =
      if open_parenthesis > close_parenthesis do
        Map.update!(records, :close_bracket, &(&1 + 1))
      else
        Map.update!(records, :close_bracket, &(&1 + 1))
        |> Map.update!(:right_missing_bracket, &[{line, "["} | &1])
      end

    analyze_aux(rest, new_records)
  end

  defp analyze_aux([{:"[", line} | rest], records) do
    records_updated =
      Map.update!(records, :open_bracket, &(&1 + 1))
      |> Map.update!(:left_missing_bracket, &[{line, "]"} | &1])

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

    open_bracket = Map.get(records, :open_bracket, 0)
    close_bracket = Map.get(records, :close_bracket, 0)

    right_missing_bracket = Map.get(records, :right_missing_bracket, [])
    left_missing_bracket = Map.get(records, :left_missing_bracket, [])

    bad_assignment = Map.get(records, :bad_assignment, nil)

    bad_expression = Map.get(records, :invalid_expression, nil)
    missing_comma = Map.get(records, :missing_comma, nil)

    check_open_close(
      {open_parenthesis, close_parenthesis, right_missing_parenthesis, left_missing_parenthesis}
    )

    check_open_close(
      {open_curly_bracket, close_curly_bracket, right_missing_curly_bracket,
       left_missing_curly_bracket}
    )

    check_open_close({open_bracket, close_bracket, right_missing_bracket, left_missing_bracket})

    check_bad_assignment(bad_assignment)
    check_bad_expression(bad_expression)
    check_missing_comma(missing_comma)

    if open_blocks == close_blocks do
      :ok
    else
      case {start_missing_blocks, end_missing_blocks} do
        {[], _} ->
          # Si estamos aquí, significa que falta un 'end'
          {line, simbol} = hd(end_missing_blocks)
          raise_error_unexpected_end(simbol, line)

        {_, []} ->
          # Si estamos aquí, significa que falta un inicio correspondiente (como 'do', 'if', 'for', etc.)
          {line, simbol} = hd(start_missing_blocks)

          raise_error_missing_end(simbol, line)
      end
    end
  end

  defp check_bad_assignment(nil) do
    :ok
  end

  defp check_bad_assignment(line) do
    raise_error_bad_assignment(line)
  end

  defp check_bad_expression(nil) do
    :ok
  end

  defp check_bad_expression(line) do
    raise_error_bad_expression(line)
  end

  defp check_missing_comma(nil) do
    :ok
  end

  defp check_missing_comma(line) do
    raise_error_missing_comma(line)
  end

  defp check_open_close({open, close, right_missing, left_missing}) do
    if open == close do
      :ok
    else
      case {right_missing, left_missing} do
        {[], _} ->
          # Si estamos aquí, significa que falta un ')'
          {line, simbol} = hd(left_missing)
          raise_error_missing_line(simbol, line)

        {_, []} ->
          # Si estamos aquí, significa que falta un (
          {line, simbol} = hd(right_missing)
          raise_error_missing_line(simbol, line)
      end
    end
  end
end
