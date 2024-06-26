defmodule CowRoll.TypeInference do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case
  import TypeInference
  import TypesUtils
  import CowRoll.Parser


  defp do_analyze(input) do
    case parse(input) do
      {:ok, tokens} ->
        infer(tokens)

      _ ->
        assert RuntimeError, "Error al parsear"
    end
  end

  describe "inference with vars" do
    test "infer a var" do
      input = "y = x"

      {output, _} = do_analyze(input)
      pattern = ~r/t\d+/

      assert Regex.match?(pattern, to_string(output))
    end

    test "infer a var with an integer" do
      input = "x = 1
      y = x"
      {output, _} = do_analyze(input)
      assert output == get_type_integer()
    end

    test "infer a var with a string" do
      input = "x = 'hola'
      y = x"
      {output, _} = do_analyze(input)
      assert output == get_type_string()
    end

    test "infer a var with a boolean" do
      input = "x = true
      y = x"
      {output, _} = do_analyze(input)
      assert output == get_type_boolean()
    end

    test "infer a var with a map" do
      input = "x = {a: true, b: false, c: {d: number, e: [1,2]}, h: 3}
      y = x"
      {output, _} = do_analyze(input)
      pattern = ~r/Map of Boolean \| Integer \| \(Map of t\d+ \| \(List of Integer\)\)/
      assert Regex.match?(pattern, output)
    end

    test "infer a var with an empty map" do
      input = "x = {}
      y = x"

      {output, _} = do_analyze(input)
      pattern = ~r/Map of t\d+/

      assert Regex.match?(pattern, output)
    end

    test "infer a var with a index map" do
      input = "x = {a: true, b: false}
      y = x['a']"
      {output, _} = do_analyze(input)
      assert output == get_type_boolean()
    end

    test "infer a var with a empty list" do
      input = "x = []
      y = x"

      {output, _} = do_analyze(input)
      pattern = ~r/List of t\d+/

      assert Regex.match?(pattern, output)
    end

    test "infer a var with a list" do
      input = "x = [true,false]
      y = x"
      {output, _} = do_analyze(input)
      assert output == "#{get_type_list()} of #{get_type_boolean()}"
    end

    test "infer a var with a index list" do
      input = "x = [[[2],[1]],3,4,5][0][1]"

      {output, _} = do_analyze(input)
      assert output == "#{get_type_list()} of #{get_type_integer()}"
    end
  end

  describe "inference" do
    test "infer a constant: integer" do
      input = "3"
      {output, _} = do_analyze(input)
      assert output == get_type_integer()
    end

    test "infer a constans" do
      input = "3
      'dos'"
      {output, _} = do_analyze(input)
      assert output == get_type_string()
    end

    test "infer a constans with previous lists" do
      input = "[3]
      'dos'"
      {output, _} = do_analyze(input)
      assert output == get_type_string()
    end

    test "infer a constant: string" do
      input = "'3'"
      {output, _} = do_analyze(input)
      assert output == get_type_string()
    end

    test "infer a constant: boolean" do
      input = "true"
      {output, _} = do_analyze(input)
      assert output == get_type_boolean()
    end

    test "infer a constant: list of strings or integers" do
      input = "['1',2,3,4,5,6]"
      expected_type = "#{get_type_list()} of #{get_type_string()} | #{get_type_integer()}"
      {output, _} = do_analyze(input)
      assert output == expected_type
    end

    test "infer a constant: tdx in list" do
      input = "[x][1][2]"

      pattern = ~r/t\d+/

      {output, _} = do_analyze(input)
      assert Regex.match?(pattern, to_string(output))
    end

    test "infer a constant: List of String | Integer | (Map of (Map of Integer)) | (Map of Integer) | (Map of List of Integer | Map of Integer)" do
      input =
        "[if true then 3 else [1,2,3] end,5,'6']"

      expected_type =
        "List of String | Integer | Integer | (List of Integer)"

      {output, _} = do_analyze(input)
      assert output == expected_type
    end

    test "infer a constant: List with maps" do
      input =
        "[{a: {b:2}},{c: 3},5,'6']"

      expected_type =
        "List of String | Integer | (Map of (Map of Integer)) | (Map of Integer)"

      {output, _} = do_analyze(input)
      assert output == expected_type
    end

    test "infer a constant: list of ints with operations" do
      input = "[1+1]"
      expected_type = "#{get_type_list()} of #{get_type_integer()}"
      {output, _} = do_analyze(input)
      assert output == expected_type
    end

    test "infer a constant: string or integer" do
      input = "['1',2,3,4,5,6][2+3]"
      expected_type = "#{get_type_string()} | #{get_type_integer()}"
      {output, _} = do_analyze(input)
      assert output == expected_type
    end

    test "infer a constant list of list: string or integer" do
      input = "[['1',2,3],[4,5,6]][3][1]"
      expected_type = "#{get_type_integer()} | #{get_type_string()}"
      {output, _} = do_analyze(input)
      assert output == expected_type
    end

    test "infer a constant: map of integers" do
      input = "{a: 1, b: 2}"
      expected_type = "#{get_type_map()} of #{get_type_integer()}"
      {output, _} = do_analyze(input)
      assert output == expected_type
    end

    test "infer a constant: map with ifs" do
      input =
        "{d: if true then [1,2,3] else {e: 3} end, e: if true then [1,2,3] else {e: 3} end}"

      expected_type = "Map of (List of Integer) | (Map of Integer)"
      {output, _} = do_analyze(input)
      assert output == expected_type
    end

    test "infer integer assignment" do
      input = "x = 3"
      {output, _} = do_analyze(input)
      assert output == get_type_integer()
    end

    test "infer boolean assignment" do
      input = "x = true"
      {output, _} = do_analyze(input)
      assert output == get_type_boolean()
    end

    test "infer string assignment" do
      input = "x = 'true'"
      {output, _} = do_analyze(input)
      assert output == get_type_string()
    end

    test "infer empty list assignment" do
      input = "x = []"

      pattern = ~r/List of t\d+/

      {output, _} = do_analyze(input)
      assert Regex.match?(pattern, output)
    end

    test "infer list of integers assignment" do
      input = "x = [1,2]"
      {output, _} = do_analyze(input)
      assert output == "#{get_type_list()} of #{get_type_integer()}"
    end

    test "infer map of integers assignment" do
      input = "x = {a: 1,b: 2}"
      {output, _} = do_analyze(input)
      assert output == "#{get_type_map()} of #{get_type_integer()}"
    end

    test "infer map with mixed types assignment" do
      input = "x = {a: 1,b:'2', c: false}"

      {output, _} = do_analyze(input)

      assert output ==
               "#{get_type_map()} of #{get_type_string()} | #{get_type_boolean()} | #{get_type_integer()}"
    end

    test "infer list with mixed types assignment" do
      input = "x = [1,'2', false]"

      {output, _} = do_analyze(input)

      assert output ==
               "#{get_type_list()} of #{get_type_string()} | #{get_type_boolean()} | #{get_type_integer()}"
    end

    test "infer nested lists of integers assignment" do
      input = "x = [[1,2,3]]"

      {output, _} = do_analyze(input)

      assert output ==
               "#{get_type_list()} of (#{get_type_list()} of #{get_type_integer()})"
    end

    test "index in list  with var" do
      input = "[[1,2,3]][x]"

      {output, _} = do_analyze(input)

      assert output ==
               "#{get_type_list()} of #{get_type_integer()}"
    end

    test "index in list with nested var" do
      input = "[[1,2,3]][x][y]"

      {output, _} = do_analyze(input)

      assert output ==
               "#{get_type_integer()}"
    end

    test "index in string with var" do
      input = "'hola buenas'[x]"

      {output, _} = do_analyze(input)

      assert output ==
               "#{get_type_string()}"
    end

    test "index in map with var" do
      input = "{a: [1,2,3], b: 3}[x]"

      {output, _} = do_analyze(input)

      assert output ==
               "Integer | (List of Integer)"
    end

    test "index in map with nested var" do
      input = "{a: [1,2,3], b: 3}[x][y]"

      {output, _} = do_analyze(input)

      assert output ==
               "#{get_type_integer()}"
    end

    test "infer list of lists with different types assignment" do
      input = "x = [[1,2,3],['1','2']]"

      {output, _} = do_analyze(input)

      assert output ==
               "#{get_type_list()} of (#{get_type_list()} of #{get_type_integer()}) | (#{get_type_list()} of #{get_type_string()})"
    end

    test "infer complex list with multiple types of lists assignment" do
      input = "x = [[1,2,3],['1','2'],[true,false]]"

      {output, _} = do_analyze(input)

      assert output ==
               "#{get_type_list()} of (#{get_type_list()} of #{get_type_boolean()}) | (#{get_type_list()} of #{get_type_integer()}) | (#{get_type_list()} of #{get_type_string()})"
    end

    test "infer extremely complex nested structures assignment" do
      input = "x = [[1,2,3],['1','2'],{a: false, b: [1,2, {re: [1,2,3]}]}]"

      {output, _} = do_analyze(input)

      assert output ==
               "#{get_type_list()} of (#{get_type_list()} of #{get_type_integer()}) | (#{get_type_list()} of #{get_type_string()}) | (#{get_type_map()} of #{get_type_boolean()} | (#{get_type_list()} of #{get_type_integer()} | (#{get_type_map()} of (#{get_type_list()} of #{get_type_integer()}))))"
    end

    test "addition of integers" do
      {output, _} = do_analyze("3 + 3")
      assert output == get_type_integer()
    end

    test "addition of integers with block of code" do
      {output, _} = do_analyze("x = 3
      4 - 3
      x+3")
      assert output == get_type_integer()
    end

    test "addition with array access" do
      {output, _} = do_analyze("3 + [2,3,4,5][2]")
      assert output == get_type_integer()
    end

    test "addition with 2 array access" do
      {output, _} = do_analyze("[3,true][1]+ [3,2,'1'][2]")
      assert output == get_type_integer()
    end

    test "negative of integers" do
      {output, _} = do_analyze("- 3")
      assert output == get_type_integer()
    end

    test "negative of integers on block" do
      {output, _} = do_analyze("- 3
      -2")
      assert output == get_type_integer()
    end

    test "not of integers" do
      {output, _} = do_analyze("not true")
      assert output == get_type_boolean()
    end

    test "not of integers on block" do
      {output, _} = do_analyze("not false
      not true")
      assert output == get_type_boolean()
    end

    test "subtraction of integers" do
      {output, _} = do_analyze("3 - 3")
      assert output == get_type_integer()
    end

    test "multiplication of integers" do
      {output, _} = do_analyze("3 * 3")
      assert output == get_type_integer()
    end

    test "division of integers" do
      {output, _} = do_analyze("3 / 3")
      assert output == get_type_integer()
    end

    test "integer division" do
      {output, _} = do_analyze("3 // 3")
      assert output == get_type_integer()
    end

    test "integer division 1" do
      {output, _} = do_analyze("[3,'3'][1] // 3")
      assert output == get_type_integer()
    end

    test "exponentiation" do
      {output, _} = do_analyze("3^3")
      assert output == get_type_integer()
    end

    test "modulo operation" do
      {output, _} = do_analyze("3 % 3")
      assert output == get_type_integer()
    end

    test "greater than comparison" do
      {output, _} = do_analyze("3 > 3")
      assert output == get_type_boolean()
    end

    test "greater than comparison with  2 enums" do
      {output, _} = do_analyze("[3,'3'][0] > {a:3, b:false}[0]")
      assert output == get_type_boolean()
    end

    test "greater than comparison with  1 enum" do
      {output, _} = do_analyze("[3,'3'][0] > 3")
      assert output == get_type_boolean()
    end

    test "greater than comparison with constant and enum" do
      {output, _} = do_analyze("3 >  [3,'3'][0]")
      assert output == get_type_boolean()
    end

    test "greater than comparison integer boolean" do
      {output, _} = do_analyze("3 > true")
      assert output == get_type_boolean()
    end

    test "greater than comparison integer tx" do
      {output, _} = do_analyze("3 > x")
      assert output == get_type_boolean()
    end

    test "greater than comparison tx boolean" do
      {output, _} = do_analyze("x > true")
      assert output == get_type_boolean()
    end

    test "greater than comparison Boolean tx" do
      {output, _} = do_analyze("true > x")
      assert output == get_type_boolean()
    end

    test "greater than or equal comparison" do
      {output, _} = do_analyze("3 >= 3")
      assert output == get_type_boolean()
    end

    test "less than comparison" do
      {output, _} = do_analyze("3 < 3")
      assert output == get_type_boolean()
    end

    test "less than or equal comparison" do
      {output, _} = do_analyze("3 <= 3")
      assert output == get_type_boolean()
    end

    test "logical or operation" do
      {output, _} = do_analyze("true or false")
      assert output == get_type_boolean()
    end

    test "logical and operation" do
      {output, _} = do_analyze("true and false")
      assert output == get_type_boolean()
    end

    test "logical and operation tx Boolean" do
      {output, _} = do_analyze("x and false")
      assert output == get_type_boolean()
    end

    test "logical and operation Boolean tx" do
      {output, _} = do_analyze("true and x")
      assert output == get_type_boolean()
    end

    test "logical and operation tx ty" do
      {output, _} = do_analyze("y and x")
      assert output == get_type_boolean()
    end

    test "logical and with comparison" do
      {output, _} = do_analyze("true and 3 > 5")
      assert output == get_type_boolean()
    end

    test "equality comparison with boolean and integer" do
      {output, _} = do_analyze("true == 3")
      assert output == get_type_boolean()
    end

    test "inequality comparison between integer and string" do
      {output, _} = do_analyze("3 != '4'")
      assert output == get_type_boolean()
    end

    test "string concatenation" do
      {output, _} = do_analyze("'hola ' ++ 'que tal'")
      assert output == get_type_string()
    end

    test "string concatenation with a String var" do
      {output, _} = do_analyze("'hola ' ++ x")
      assert output == get_type_string()
    end

    test "string concatenation with a var String" do
      {output, _} = do_analyze("x ++ ' Mundo'")
      assert output == get_type_string()
    end

    test "string concatenation with a var var" do
      {output, _} = do_analyze("x ++ y")

      pattern = ~r/List of t\d+ | String/

      assert Regex.match?(pattern, to_string(output))
    end

    test "list concatenation" do
      {output, _} = do_analyze("[2,3,1] ++ [4,3]")
      assert output == get_type_list()
    end

    test "list subtraction" do
      {output, _} = do_analyze("[2,3,1] -- [4,3]")
      assert output == get_type_list()
    end

    test "negative number with var" do
      input = "
      -x"
      {output, _} = do_analyze(input)
      assert output == get_type_integer()
    end

    test "negative boolean with var" do
      input = "
      not x"
      {output, _} = do_analyze(input)
      assert output == get_type_boolean()
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
      {output, _} = do_analyze(input)
      assert output == get_type_integer()
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
      {output, _} = do_analyze(input)
      assert output == get_type_integer()
    end

    test "basic call function with parameters with var" do
      input = "function hola_mundo (msg, range) do
           for participants <- 1..range do
             msg
           end
         end;
         x= 'hola mundo '
         y= 2
         hola_mundo(x, y)
         "
      {output, _} = do_analyze(input)

      assert output == "List of String"
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
      {output, _} = do_analyze(input)
      assert output == get_type_integer()
    end

    test "infer simple function returns integer" do
      input = """
      function f() do
        5+4
      end
      1-f()
      """

      {output, _} = do_analyze(input)
      assert output == get_type_integer()
    end

    test "infer sum function returns integer" do
      input = """
      function suma(x,y) do
        x+y
      end
      suma(3,4)
      """

      {output, _} = do_analyze(input)
      assert output == get_type_integer()
    end

    test "infer conditional function returns string" do
      input = """
      function suma(x,y) do
        z = x+y
        if(z > 1) then
          'bien'
        else
          'mal'
        end
      end
      suma(3,4)
      """

      {output, _} = do_analyze(input)
      assert output == get_type_string()
    end

    test "infer recursive function roll_dices returns integer" do
      input = """
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
      roll_dices(3,4)
      """

      {output, _} = do_analyze(input)
      assert output == get_type_integer()
    end

    test "infer roll_ability_score function returns integer" do
      input = """
      function roll_ability_score() do
        rolls = [0,0,0,0]
        for x <- 0..3 do
            rolls[x] = 3
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
      end
      """

      {output, _} = do_analyze(input)
      assert output == get_type_integer()
    end
  end

  describe "static errors" do
    test "error with <=" do
      input = "[1]<=2
           "

      assert_raise(
        TypeError,
        "Error at line 1 in '<=' operation, Incompatible types: List of Integer, Integer were found but Boolean, Boolean were expected",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "error with <" do
      input = "[1]<2
           "

      assert_raise(
        TypeError,
        "Error at line 1 in '<' operation, Incompatible types: List of Integer, Integer were found but Boolean, Boolean were expected",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "error with >=" do
      input = "[1]>=2
           "

      assert_raise(
        TypeError,
        "Error at line 1 in '>=' operation, Incompatible types: List of Integer, Integer were found but Boolean, Boolean were expected",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "basic call range x..y with not integers" do
      input = "
             for participants <- '1'..range do
               msg
             end
           "

      pattern =
        ~r/Error at line 2 in 'range' operation, Incompatible types: String, t\d+ were found but Integer, Integer were expected/

      assert_raise(TypeError, fn ->
        do_analyze(input)
      end)
      |> assert_message_matches(pattern)
    end

    defp assert_message_matches(error, pattern) do
      assert Regex.match?(pattern, Exception.message(error))
    end

    test "functions with incorrect types" do
      input = "function hola_mundo (msg, range) do
        for participants <- 1..range do
          msg
        end
      end;
      hola_mundo('hola mundo','2')
           "

      assert_raise(
        TypeError,
        "Error at line 6: Type mismatch in function 'hola_mundo', expected parameter 'range': Integer but got 'String'",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "basic call function with bad number of parameters" do
      input = "function hola_mundo (msg, range) do
             for participants <- 1..range do
               msg
             end
           end;
           hola_mundo('hola mundo')
           "

      assert_raise(
        TypeError,
        "Error at line 6: bad number of parameters on 'hola_mundo' expected 2 but got 1",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "basic call function with moreparameters" do
      input = "function hola_mundo (a) do
             for participants <- 1..range do
               msg
             end
           end;
           hola_mundo('hola', 'mundo')
           "

      assert_raise(
        TypeError,
        "Error at line 6: bad number of parameters on 'hola_mundo' expected 1 but got 2",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "addition with boolean should raise TypeError" do
      input = "3 + true"

      assert_raise(
        TypeError,
        "Error at line 1 in '+' operation, Incompatible types: Integer, Boolean were found but Integer, Integer were expected",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "addition with list should raise TypeError" do
      input = "3 + [1,2,3]"

      assert_raise(
        TypeError,
        "Error at line 1 in '+' operation, Incompatible types: Integer, List of Integer were found but Integer, Integer were expected",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "addition with map should raise TypeError" do
      input = "3 + {a: 2}"

      assert_raise(
        TypeError,
        "Error at line 1 in '+' operation, Incompatible types: Integer, Map of Integer were found but Integer, Integer were expected",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "greater than with list should raise TypeError" do
      input = "3>[3,2,1]"

      assert_raise(
        TypeError,
        "Error at line 1 in '>' operation, Incompatible types: Integer, List of Integer were found but Boolean, Boolean were expected",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "greater than with map should raise TypeError" do
      input = "3>{a: 2}"

      assert_raise(
        TypeError,
        "Error at line 1 in '>' operation, Incompatible types: Integer, Map of Integer were found but Boolean, Boolean were expected",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "Index error with Maps" do
      input = "{a: 2}[true]"

      assert_raise(
        TypeError,
        "The index must be an Integer or a String but Boolean was found",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "Index error with List" do
      input = "[1,2,3][true]"

      assert_raise(
        TypeError,
        "The index must be an Integer but Boolean was found",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "Index error with String" do
      input = "'hola buenas'[true]"

      assert_raise(
        TypeError,
        "The index must be an Integer but Boolean was found",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "infer a constant: out of index with constants on a LIst" do
      input = "[2][1][1]"

      assert_raise(
        TypeError,
        "Error: Attempt to access index with deep 2 on a List of Integer",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "infer a constant: out of index with constants on a Map" do
      input = "{a:2}['a']['b']"

      assert_raise(
        TypeError,
        "Error: Attempt to access index with deep 2 on a Map of Integer",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "infer a constant: out of index with vars" do
      input = "[2][z][y]"

      assert_raise(
        TypeError,
        "Error: Attempt to access index with deep 2 on a List of Integer",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "infer a constant: out of index with vars on Map" do
      input = "{a: 2}[z][y]"

      assert_raise(
        TypeError,
        "Error: Attempt to access index with deep 2 on a Map of Integer",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "infer a constant: out of index with vars on String" do
      input = "'hola buenas'[z][y]"

      assert_raise(
        TypeError,
        "Error: Attempt to access index with deep 2 on a String",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "infer a constant: out of index with constants on String" do
      input = "'hola buenas'[1][2]"

      assert_raise(
        TypeError,
        "Error: Attempt to access index with deep 2 on a String",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "Index error with map out of index" do
      input = "{a:1}[1][2]"

      assert_raise(
        TypeError,
        "Error: Attempt to access index with deep 2 on a Map of Integer",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "string concatenation with integer should raise TypeError" do
      input = "'hola' ++ 3"

      assert_raise(
        TypeError,
        "Error at line 1 in '++' operation, Incompatible types: String, Integer were found but String, String were expected",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "string concatenation with list of strings should raise TypeError" do
      input = "'hola' ++ ['23']"

      assert_raise(
        TypeError,
        "Error at line 1 in '++' operation, Incompatible types: String, List of String were found but String, String were expected",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "list indexing followed by concatenation should raise TypeError" do
      input = "[123][0] ++ [3,2,1]"

      assert_raise(
        TypeError,
        "Error at line 1 in '++' operation, Incompatible types: Integer, List of Integer were found but String, String were expected",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "string concatenation with list of integers should raise TypeError" do
      input = "'4' ++ [3,2,1]"

      assert_raise(
        TypeError,
        "Error at line 1 in '++' operation, Incompatible types: String, List of Integer were found but String, String were expected",
        fn ->
          do_analyze(input)
        end
      )
    end

    test "map concatenation with list should raise TypeError" do
      input = "{a: 5} ++ [3,2,1]"

      assert_raise(
        TypeError,
        "Error at line 1 in '++' operation, Incompatible types: Map of Integer, List of Integer were found but String, String were expected",
        fn ->
          do_analyze(input)
        end
      )
    end
  end
end
