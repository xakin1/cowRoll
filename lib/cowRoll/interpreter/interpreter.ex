defmodule CowRoll.Interpreter do
  import CowRoll.Parser
  import TreeNode
  import TypeError
  import NestedIndexFinder
  import Arrays
  import TypesUtils
  import Exceptions.RuntimeError

  @type expr_ast ::
          {:mult, expr_ast, expr_ast}
          | {:divi, expr_ast, expr_ast}
          | {:plus, expr_ast, expr_ast}
          | {:minus, expr_ast, expr_ast}
          | {:negative, expr_ast}
          | {:not_operation, expr_ast}
          | {:assignment, expr_ast, expr_ast}
          | {:strict_more, expr_ast, expr_ast}
          | {:more_equal, expr_ast, expr_ast}
          | {:strict_less, expr_ast, expr_ast}
          | {:less_equal, expr_ast, expr_ast}
          | {:equal, expr_ast, expr_ast}
          | {:not_equal, expr_ast, expr_ast}
          | {:and_operation, expr_ast, expr_ast}
          | {:or_operation, expr_ast, expr_ast}
          | {:round_div, expr_ast, expr_ast}
          | {:mod, expr_ast, expr_ast}
          | {:pow, expr_ast, expr_ast}
          | {:number, number}
          | {:negative_number, number}
          | {:boolean, boolean}
          | {:string, String.t()}
          | {:not_defined, String.t()}
          | {:negative, expr_ast}
          | {:name, String.t()}
          | {:list, expr_ast}
          | {:assignment, {:name, String.t()}, expr_ast}
          | {:concat, expr_ast, expr_ast}
          | {:range, expr_ast}
          | {:for_loop, {:name, String.t()}, expr_ast, expr_ast}
          | {:if_then_else, expr_ast, expr_ast, expr_ast}
          | {:assignment_function, {:function_name, String.t()}, {:parameters, expr_ast},
             {:function_code, expr_ast}}
          | {:call_function, String.t(), {:parameters, expr_ast}}
          | {:call_function, String.t()}

  @spec eval_input(any()) :: any()
  def eval_input(input) do
    # Creamos un arbol que va a tener el scope de las variables
    node = create_tree()
    load_modules()

    {:ok, list_sentences} = parse(input)
    result = eval_block(node.id, list_sentences)

    delete_tree()
    result
  end

  defp load_modules() do
    add_function_to_scope("rand", "range")
    add_function_to_scope("rand_between", "range")
  end

  # para evaluar una lista de tuplas y que te devuelva los parametros en un array
  defp eval_parameters(scope, parameters) do
    case parameters do
      {head, tail} when is_tuple(head) ->
        [eval(scope, head), eval_parameters(scope, tail)]

      _ ->
        eval(scope, parameters)
    end
  end

  defp fech(nil, _) do
    nil
  end

  defp fech(list, [index | tail]) do
    result =
      case list do
        list when is_list(list) -> fech_line(list, index)
        string when is_bitstring(string) -> fech_string(string, index)
        map when is_map(map) -> fech_map(map, index)
        error -> raise_error_type(error)
      end

    fech(result, tail)
  end

  defp fech(list, []) do
    list
  end

  defp fech_map(map, index) do
    case Map.fetch(map, index) do
      {:ok, value} -> value
      _ -> nil
    end
  end

  defp fech_string(string, index) do
    case index do
      index when is_integer(index) ->
        String.at(string, index)

      # Es necesario debido a que tenemos que permitir string string en los indices por culpa de los mapas
      # sin embargo indexar un string con un string no está permitido
      _ ->
        raise_index_error(get_type(index))
    end
  end

  defp fech_line(list, index) do
    case index do
      index when is_integer(index) ->
        Enum.at(list, index)
    end
  end

  # Necesario para analizar más de una sentencia
  defp eval_block(scope, tuple) do
    case tuple do
      {first_element, second_element} when is_tuple(first_element) ->
        eval(scope, first_element)
        eval_block(scope, second_element)

      _ ->
        eval(scope, tuple)
    end
  end

  # Necesario para construir una lista
  defp eval_line(scope, elements, list) do
    case elements do
      {:list, _} ->
        [eval(scope, elements) | list]

      {first_element, second_element} when is_tuple(second_element) ->
        eval_line(scope, second_element, [eval(scope, first_element) | list])

      _ ->
        [eval(scope, elements) | list]
    end
  end

  # Necesario para construir una lista
  defp eval_map(scope, map, map_line) do
    case map_line do
      {{{:name, key, _line}, value}, second_element} when is_tuple(second_element) ->
        map = Map.put(map, key, eval(scope, value))
        eval_map(scope, map, second_element)

      {{:name, key, _line}, value} ->
        Map.put(map, key, eval(scope, value))
    end
  end

  defp eval(_, {:number, number, _line}), do: number

  defp eval(_, {:boolean, bool, _line}), do: bool

  defp eval(_, {:string, string, _line}) do
    case String.match?(string, ~r/^'.*'$/s) do
      true -> String.trim(string, "'")
      false -> String.trim(string, "\"")
    end
  end

  defp eval(scope, {:negative, expresion, _}) do
    -eval(scope, expresion)
  end

  defp eval(scope, {:not_operation, expresion, _}) do
    not eval(scope, expresion)
  end

  defp eval(scope, {:name, variable, line}) do
    case get_variable_from_scope(scope, variable) do
      :not_found -> runtimeError_raise_error(variable, line)
      value -> value
    end
  end

  defp eval(scope, {:list, list}) do
    case list do
      {first_element, second_element} when is_tuple(first_element) ->
        list = eval_line(scope, second_element, [eval(scope, first_element)])
        # es más rápido darle la vuelta al final que construirla en orden
        Enum.reverse(list)

      nil ->
        []

      _ ->
        [eval(scope, list)]
    end
  end

  defp eval(scope, {:index, {index, list}}) do
    struct = eval(scope, list)
    index = find_index_pattern(index)
    eval_index = Enum.map(index, &eval(scope, &1))
    fech(struct, eval_index)
  end

  defp eval(scope, {:map, list}) do
    case list do
      {{{:name, key, _line}, value}, second_element} when is_tuple(value) ->
        map = %{key => eval(scope, value)}

        eval_map(scope, map, second_element)

      nil ->
        Map.new()

      {{:name, key, _line}, value} ->
        %{key => eval(scope, value)}
    end
  end

  defp eval(scope, {:assignment, var, value}) do
    case var do
      {:name, var_name, _line} ->
        case value do
          {:assignment_function, {:function_name, {:name, _, _line}}, {:parameters, parameters},
           {:function_code, code}} ->
            eval(
              scope,
              {:assignment_function, {:function_name, {:name, var_name, 1}},
               {:parameters, parameters}, {:function_code, code}}
            )

            nil

          _ ->
            add_variable_to_scope(scope, var_name, eval(scope, value))
        end

      {:index, _} ->
        case find_name_pattern(var) do
          {{:name, var_name, line}, index} ->
            eval_index = Enum.map(index, &eval(scope, &1))
            var = {:name, var_name, line}
            array = eval(scope, var)
            value_to_update = eval(scope, value)
            new_array = set_element_at(array, eval_index, value_to_update)
            add_variable_to_scope(scope, var_name, new_array)
        end
    end
  end

  defp eval(scope, {:concat, {left_expression, right_expression}, _}) do
    left_expression_evaluated = eval(scope, left_expression)
    right_expression_evaluated = eval(scope, right_expression)

    case left_expression_evaluated do
      left_expression when is_list(left_expression) ->
        left_expression ++ right_expression_evaluated

      left_expression when is_bitstring(left_expression) ->
        left_expression_evaluated <> right_expression_evaluated
    end
  end

  defp eval(scope, {:subtract, {left_expression, right_expression}, _}) do
    eval(scope, left_expression) -- eval(scope, right_expression)
  end

  defp eval(scope, {:plus, {left_expression, right_expression}, _}) do
    eval(scope, left_expression) + eval(scope, right_expression)
  end

  defp eval(scope, {:minus, {left_expression, right_expression}, _}) do
    eval(scope, left_expression) - eval(scope, right_expression)
  end

  defp eval(scope, {:mult, {left_expression, right_expression}, _}) do
    eval(scope, left_expression) * eval(scope, right_expression)
  end

  defp eval(scope, {:divi, {left_expression, right_expression}, _}) do
    dividend = eval(scope, left_expression)
    divisor = eval(scope, right_expression)

    case {dividend, divisor} do
      {_, 0} ->
        raise ArithmeticError, "Error: division by 0"

      {dividend, divisor} ->
        div(dividend, divisor)
    end
  end

  defp eval(scope, {:round_div, {left_expression, right_expression}, _}) do
    dividend = eval(scope, left_expression)
    divisor = eval(scope, right_expression)

    case {dividend, divisor} do
      {_, 0} ->
        raise ArithmeticError, "Error: division by 0"

      {dividend, divisor} ->
        div(dividend, divisor) + ceil(rem(dividend, divisor) / divisor)
    end
  end

  defp eval(scope, {:mod, {left_expression, right_expression}, _}) do
    dividend = eval(scope, left_expression)
    divisor = eval(scope, right_expression)

    case {dividend, divisor} do
      {_, 0} ->
        raise ArithmeticError, "Error: division by 0"

      {dividend, divisor} ->
        Integer.mod(dividend, divisor)
    end
  end

  defp eval(scope, {:pow, {left_expression, right_expression}, _}) do
    Integer.pow(eval(scope, left_expression), eval(scope, right_expression))
  end

  defp eval(scope, {:strict_more, {left_expression, right_expression}, _}),
    do: eval(scope, left_expression) > eval(scope, right_expression)

  defp eval(scope, {:more_equal, {left_expression, right_expression}, _}),
    do: eval(scope, left_expression) >= eval(scope, right_expression)

  defp eval(scope, {:strict_less, {left_expression, right_expression}, _}),
    do: eval(scope, left_expression) < eval(scope, right_expression)

  defp eval(scope, {:less_equal, {left_expression, right_expression}, _}),
    do: eval(scope, left_expression) <= eval(scope, right_expression)

  defp eval(scope, {:equal, {left_expression, right_expression}, _}),
    do: eval(scope, left_expression) == eval(scope, right_expression)

  defp eval(scope, {:not_equal, {left_expression, right_expression}, _}),
    do: eval(scope, left_expression) != eval(scope, right_expression)

  defp eval(scope, {:and_operation, {left_expression, right_expression}, _}) do
    eval(scope, left_expression) and eval(scope, right_expression)
  end

  defp eval(scope, {:or_operation, {left_expression, right_expression}, _}) do
    eval(scope, left_expression) or eval(scope, right_expression)
  end

  defp eval(scope, {:range, range}) do
    case range do
      {first, _} when is_atom(first) ->
        eval(scope, range)

      {first, _, _} when is_atom(first) ->
        eval(scope, range)

      {first, last} ->
        {eval(scope, first), eval(scope, last)}
    end
  end

  defp eval(scope, {:for_loop, {:name, var_name, _line}, range, expresion}) do
    scope = add_scope(scope, :for_loop)

    result =
      case eval(scope, range) do
        {first, last} ->
          for(x <- first..last) do
            add_variable_to_scope(scope, var_name, x)
            eval(scope, expresion)
          end

        variable ->
          for(x <- variable) do
            add_variable_to_scope(scope, var_name, x)
            eval(scope, expresion)
          end
      end

    remove_scope(:for_loop)
    result
  end

  defp eval(_, nil) do
  end

  defp eval(scope, {:if_then_else, condition, then_expression, else_expression, _}) do
    node = add_scope(scope, :for_loop)
    condition = eval(scope, condition)

    result =
      if condition do
        eval_block(node, then_expression)
      else
        eval_block(node, else_expression)
      end

    remove_scope(:for_loop)
    result
  end

  defp eval(
         _,
         {:assignment_function, {:function_name, function_name}, {:parameters, parameters},
          {:function_code, function_code}}
       ) do
    add_function_to_scope(function_name, parameters, function_code)
  end

  defp eval(
         scope,
         {:call_function, function_name, {:parameters, parameters}}
       ) do
    case get_fuction_from_scope(function_name) do
      {false, name, line} ->
        raise runtimeError_raise_error_function_missing(name, line)

      {parameters_to_replace, code} ->
        call_function(scope, function_name, parameters, parameters_to_replace, code)

      {_, erlang_function, module, _, :erlang} ->
        # Necesario para llamar a las funciones de erlang
        array_parameters =
          case parameters do
            {head, _} when is_tuple(head) -> eval_parameters(scope, parameters)
            nil -> []
            parameters -> [eval(scope, parameters)]
          end

        apply(module, erlang_function, array_parameters)

      {_, elixir_function, module, _, :elixir} ->
        array_parameters =
          case parameters do
            {head, _} when is_tuple(head) ->
              eval_parameters(scope, parameters)

            nil ->
              []
          end

        array_parameters =
          case array_parameters do
            # Transformar la lista en un rango
            [start, stop] when is_integer(start) and is_integer(stop) -> [start..stop]
            _ -> [0]
          end

        apply(module, elixir_function, array_parameters)
    end
  end

  defp call_function(
         scope,
         {:name, function_name, line},
         parameters,
         parameters_to_replace,
         code
       ) do
    node = add_scope(scope, {:name, function_name})

    case initialize_function(scope, parameters_to_replace, parameters) do
      :error ->
        raise_error(line, function_name, parameters_to_replace, parameters)

      _ ->
        result = eval_block(node, code)
        remove_scope(function_name)
        result
    end
  end

  defp initialize_function(scope, parameters_to_replace, parameters) do
    case {parameters_to_replace, parameters} do
      {{parameter_to_replace_head, _, _}, {parameter_head, _, _}}
      when is_atom(parameter_to_replace_head) and is_atom(parameter_head) ->
        eval(scope, {:assignment, parameters_to_replace, parameters})
        initialize_function(scope, {}, {})

      {{parameter_to_replace_head, tail}, {parameter_head, _, _}}
      when is_tuple(parameter_to_replace_head) and is_atom(parameter_head) ->
        eval(scope, {:assignment, parameter_to_replace_head, parameters})
        initialize_function(scope, tail, {})

      {{parameter_to_replace_head, _, _}, {parameter_head, tail}}
      when is_atom(parameter_to_replace_head) and is_tuple(parameter_head) ->
        eval(scope, {:assignment, parameters_to_replace, parameter_head})
        initialize_function(scope, {}, tail)

      {{parameter_to_replace_head, tail_to_replace}, {parameter_head, tail}}
      when is_tuple(parameter_to_replace_head) and is_tuple(parameter_head) ->
        eval(scope, {:assignment, parameter_to_replace_head, parameter_head})
        initialize_function(scope, tail_to_replace, tail)

      {{}, {}} ->
        :ok

      {nil, nil} ->
        :ok

      {parameter_to_replace_head, parameter_head}
      when is_tuple(parameter_to_replace_head) and is_tuple(parameter_head) ->
        eval(scope, {:assignment, parameter_to_replace_head, parameter_head})
        initialize_function(scope, {}, {})

      _ ->
        :error
    end
  end
end
