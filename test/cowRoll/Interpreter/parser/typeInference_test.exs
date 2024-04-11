defmodule CowRoll.TypeInference do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case
  import TypeInference
  import TypesUtils

  defp do_analize(input) do
    case Parser.parse(input) do
      {:ok, tokens} -> infer(tokens)
      _ -> assert RuntimeError, "Error al parsear"
    end
  end

  describe "inference with vars" do
    test "infer a var" do
      input = "y = x"
      assert do_analize(input) == {:t1, %{}}
    end

    test "infer a var with an integer" do
      input = "x = 1
      y = x"
      assert do_analize(input) == {get_type_integer(), %{}}
    end

    test "infer a var with a string" do
      input = "x = 'hola'
      y = x"
      assert do_analize(input) == {get_type_string(), %{}}
    end

    test "infer a var with a boolean" do
      input = "x = true
      y = x"
      assert do_analize(input) == {get_type_boolean(), %{}}
    end

    test "infer a var with a map" do
      input = "x = {a: true, b: false, c: {d: number, e: [1,2]}, h: 3}
      y = x"

      assert do_analize(input) ==
               {"#{get_type_map()} of #{get_type_boolean()} | #{get_type_integer()} | (#{get_type_map()} of t1 | (#{get_type_list()} of #{get_type_integer()}))",
                %{}}
    end

    test "infer a var with an empty map" do
      input = "x = {}
      y = x"
      assert do_analize(input) == {"#{get_type_map()} of t1", %{}}
    end

    test "infer a var with a index map" do
      input = "x = {a: true, b: false}
      y = x['a']"
      assert do_analize(input) == {get_type_boolean(), %{}}
    end

    test "infer a var with a list" do
      input = "x = []
      y = x"
      assert do_analize(input) == {"#{get_type_list()} of t1", %{}}

      input = "x = [true,false]
      y = x"
      assert do_analize(input) == {"#{get_type_list()} of #{get_type_boolean()}", %{}}
    end
  end

  describe "inference" do
    test "infer a constant: integer" do
      input = "3"
      assert do_analize(input) == {get_type_integer(), %{}}
    end

    test "infer a constant: string" do
      input = "'3'"
      assert do_analize(input) == {get_type_string(), %{}}
    end

    test "infer a constant: boolean" do
      input = "true"
      assert do_analize(input) == {get_type_boolean(), %{}}
    end

    test "infer a constant: list of strings or integers" do
      input = "['1',2,3,4,5,6]"
      expected_type = "#{get_type_list()} of #{get_type_string()} | #{get_type_integer()}"
      assert do_analize(input) == {expected_type, %{}}
    end

    test "infer a constant: string or integer" do
      input = "['1',2,3,4,5,6][2+3]"
      expected_type = "#{get_type_string()} | #{get_type_integer()}"
      assert do_analize(input) == {expected_type, %{}}
    end

    test "infer a constant list of list: string or integer" do
      input = "[['1',2,3],[4,5,6]][3][1]"
      expected_type = "#{get_type_integer()} | #{get_type_string()}"
      assert do_analize(input) == {expected_type, %{}}
    end

    test "infer a constant: map of integers" do
      input = "{a: 1, b: 2}"
      expected_type = "#{get_type_map()} of #{get_type_integer()}"
      assert do_analize(input) == {expected_type, %{}}
    end

    test "infer assignment" do
      input = "x = 3"
      assert do_analize(input) == {get_type_integer(), %{}}

      input = "x = true"
      assert do_analize(input) == {get_type_boolean(), %{}}

      input = "x = 'true'"
      assert do_analize(input) == {get_type_string(), %{}}

      input = "x = []"
      assert do_analize(input) == {"#{get_type_list()} of t1", %{}}

      input = "x = [1,2]"
      assert do_analize(input) == {"#{get_type_list()} of #{get_type_integer()}", %{}}

      input = "x = {a: 1,b: 2}"
      assert do_analize(input) == {"#{get_type_map()} of #{get_type_integer()}", %{}}

      input = "x = {a: 1,b:'2', c: false}"

      assert do_analize(input) ==
               {"#{get_type_map()} of #{get_type_string()} | #{get_type_boolean()} | #{get_type_integer()}",
                %{}}

      input = "x = [1,'2', false]"

      assert do_analize(input) ==
               {"#{get_type_list()} of #{get_type_string()} | #{get_type_boolean()} | #{get_type_integer()}",
                %{}}

      input = "x = [[1,2,3]]"

      assert do_analize(input) ==
               {"#{get_type_list()} of (#{get_type_list()} of #{get_type_integer()})", %{}}

      input = "x = [[1,2,3],['1','2']]"

      assert do_analize(input) ==
               {"#{get_type_list()} of (#{get_type_list()} of #{get_type_integer()}) | (#{get_type_list()} of #{get_type_string()})",
                %{}}

      input = "x = [[1,2,3],['1','2'],[true,false]]"

      assert do_analize(input) ==
               {"#{get_type_list()} of (#{get_type_list()} of #{get_type_boolean()}) | (#{get_type_list()} of #{get_type_integer()}) | (#{get_type_list()} of #{get_type_string()})",
                %{}}

      input = "x = [[1,2,3],['1','2'],{a: false, b: [1,2, {re: [1,2,3]}]}]"

      assert do_analize(input) ==
               {"#{get_type_list()} of (#{get_type_list()} of #{get_type_integer()}) | (#{get_type_list()} of #{get_type_string()}) | (#{get_type_map()} of #{get_type_boolean()} | (#{get_type_list()} of #{get_type_integer()} | (#{get_type_map()} of (#{get_type_list()} of #{get_type_integer()}))))",
                %{}}
    end

    test "addition of integers" do
      assert do_analize("3 + 3") == {get_type_integer(), %{}}
    end

    test "addition with array access" do
      assert do_analize("3 + [2,3,4,5][2]") == {get_type_integer(), %{}}
    end

    test "subtraction of integers" do
      assert do_analize("3 - 3") == {get_type_integer(), %{}}
    end

    test "multiplication of integers" do
      assert do_analize("3 * 3") == {get_type_integer(), %{}}
    end

    test "division of integers" do
      assert do_analize("3 / 3") == {get_type_integer(), %{}}
    end

    test "integer division" do
      assert do_analize("3 // 3") == {get_type_integer(), %{}}
    end

    test "exponentiation" do
      assert do_analize("3^3") == {get_type_integer(), %{}}
    end

    test "modulo operation" do
      assert do_analize("3%3") == {get_type_integer(), %{}}
    end

    test "greater than comparison" do
      assert do_analize("3>3") == {get_type_boolean(), %{}}
    end

    test "greater than or equal comparison" do
      assert do_analize("3>=3") == {get_type_boolean(), %{}}
    end

    test "less than comparison" do
      assert do_analize("3<3") == {get_type_boolean(), %{}}
    end

    test "less than or equal comparison" do
      assert do_analize("3<=3") == {get_type_boolean(), %{}}
    end

    test "logical or operation" do
      assert do_analize("true or false") == {get_type_boolean(), %{}}
    end

    test "logical and operation" do
      assert do_analize("true and false") == {get_type_boolean(), %{}}
    end

    test "logical and with comparison" do
      assert do_analize("true and 3 > 5") == {get_type_boolean(), %{}}
    end

    test "equality comparison with boolean and integer" do
      assert do_analize("true == 3") == {get_type_boolean(), %{}}
    end

    test "inequality comparison between integer and string" do
      assert do_analize("3 != '4'") == {get_type_boolean(), %{}}
    end

    test "string concatenation" do
      assert do_analize("'hola ' ++ 'que tal'") == {get_type_string(), %{}}
    end

    test "list concatenation" do
      assert do_analize("[2,3,1] ++ [4,3]") == {get_type_list(), %{}}
    end

    test "list subtraction" do
      assert do_analize("[2,3,1] -- [4,3]") == {get_type_list(), %{}}
    end

    test "loop with integer accumulation" do
      input = "
        y = 0;
        begin = 3;
        finish = 6;
        for x <- begin..finish do
          y = y + x
        end;
        y"
      assert do_analize(input) == {get_type_integer(), %{}}
    end

    test "loop with integer accumulation and lists" do
      input = "
           y = 0;
           z = [3,4,5,6];

           for x <- z do
             y = y + x
           end;
           y
           "
      assert do_analize(input) == {get_type_integer(), %{}}
    end

    test "test statements" do
      input = "

      function rand(x) do
        x + 3
      end

      function roll_dices(dices, faces) do
        dices%faces + 3
       end
      function roll_dices(number_of_dices, number_of_face) do
        if (number_of_dices<=0 or number_of_face <0 ) then
          -1
        else
          roll = rand(number_of_face) - 1
          roll + roll_dices(number_of_dices - 1, number_of_face)
        end
      end
      roll_dices(3,4)"
      assert do_analize(input) == {get_type_integer(), %{}}
    end

    test "infer functions with functions" do
      input = "
        function f() do
          5+4
        end
        1-f()"
      assert do_analize(input) == {get_type_integer(), %{}}

      input = "
      function suma(x,y) do
        x+y
      end
      suma(3,4)"
      assert do_analize(input) == {get_type_integer(), %{}}

      input = "
      function suma(x,y) do
        z = x+y
        if(z > 1) then
          'bien'
        else
          'mal'
        end
      end
      suma(3,4)"
      assert do_analize(input) == {get_type_string(), %{}}
      input = "

      function rand(x) do
        x + 3
      end

      function roll_dices(dices, faces) do
        dices%faces + 3
       end
      function roll_dices(number_of_dices, number_of_face) do
        if (number_of_dices<=0 or number_of_face <0 ) then
          -1
        else
          roll = rand(number_of_face) - 1
          roll + roll_dices(number_of_dices - 1, number_of_face)
        end
      end
      roll_dices(3,4)"
      assert do_analize(input) == {get_type_integer(), %{}}
      input = "

      function roll_ability_score() do
        rolls = [0,0,0,0]
        for x <- 0..3 do
            rolls[x  ] = 3
        end

        min_index = 0
        for i <- 0..3 do
          if (rolls[i] < rolls[min_index]) then
            min_index = i
          end
        end

        result = 0
        for i <- 0..3 do
          if (i != min_index) then
            result = result + rolls[i];
          end
        end

        result
      end"
      assert do_analize(input) == {get_type_integer(), %{}}
    end
  end

  describe "static errors" do
    test "wrong type in functions" do
      input = "3 + true"

      assert_raise(
        TypeError,
        "Incompatible types: #{get_type_integer()}, #{get_type_boolean()}",
        fn ->
          do_analize(input)
        end
      )

      input = "3 + [1,2,3]"

      assert_raise(
        TypeError,
        "Incompatible types: #{get_type_integer()}, #{get_type_list()} of #{get_type_integer()}",
        fn ->
          do_analize(input)
        end
      )

      input = "3 + {a: 2}"

      assert_raise(
        TypeError,
        "Incompatible types: #{get_type_integer()}, #{get_type_map()} of #{get_type_integer()}",
        fn ->
          do_analize(input)
        end
      )

      input = "3 / 0"

      assert_raise(
        TypeError,
        "Incompatible types: #{get_type_integer()}, #{get_type_map()} of #{get_type_integer()}",
        fn ->
          do_analize(input)
        end
      )

      input = "3>true"

      assert_raise(
        TypeError,
        "Incompatible types: #{get_type_integer()}, #{get_type_boolean()}",
        fn ->
          do_analize(input)
        end
      )

      input = "3>[3,2,1]"

      assert_raise(
        TypeError,
        "Incompatible types: #{get_type_integer()}, #{get_type_list()} of #{get_type_integer()}",
        fn ->
          do_analize(input)
        end
      )

      input = "3>{a: 2}"

      assert_raise(
        TypeError,
        "Incompatible types: #{get_type_integer()}, #{get_type_map()} of #{get_type_integer()}",
        fn ->
          do_analize(input)
        end
      )

      input = "'hola' ++ 3"

      assert_raise(
        TypeError,
        "Incompatible types: #{get_type_string()}, #{get_type_integer()}",
        fn ->
          do_analize(input)
        end
      )

      input = "'hola' ++ ['23']"

      assert_raise(
        TypeError,
        "Incompatible types: #{get_type_string()}, #{get_type_list()} of #{get_type_string()}",
        fn ->
          do_analize(input)
        end
      )

      input = "[123][0] ++ [3,2,1] "

      assert_raise(
        TypeError,
        "Incompatible types: #{get_type_integer()}, #{get_type_list()} of #{get_type_integer()}",
        fn ->
          do_analize(input)
        end
      )

      input = "'4' ++ [3,2,1] "

      assert_raise(
        TypeError,
        "Incompatible types: #{get_type_string()}, #{get_type_list()} of #{get_type_integer()}",
        fn ->
          do_analize(input)
        end
      )

      input = "{a: 5} ++ [3,2,1] "

      assert_raise(
        TypeError,
        "Incompatible types: #{get_type_map()} of #{get_type_integer()}, #{get_type_list()} of #{get_type_integer()}",
        fn ->
          do_analize(input)
        end
      )
    end
  end
end
