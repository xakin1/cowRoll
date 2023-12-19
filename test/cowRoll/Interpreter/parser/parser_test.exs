defmodule CowRoll.ParserTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "detect basic operations correctly" do
    test "parse integer" do
      # Uso del analizador léxico en otro módulo
      input = "1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [number: [1]]

      input = "1 "
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [number: [1]]

      input = " 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [number: [1]]

      input = " 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [number: [1]]
    end

    test "parse plus operation" do
      # Uso del analizador léxico en otro módulo
      input = "1+1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [plus: [number: [1], number: [1]]]

      input = "1+ 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [plus: [number: [1], number: [1]]]

      input = "1 +1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [plus: [number: [1], number: [1]]]

      input = "1 + 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [plus: [number: [1], number: [1]]]

      input = " 1 + 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [plus: [number: [1], number: [1]]]

      input = " 1 + 1 "
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [plus: [number: [1], number: [1]]]
    end

    test "parse minus operation" do
      # Uso del analizador léxico en otro módulo
      input = "1-1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [minus: [number: [1], number: [1]]]

      input = "1- 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [minus: [number: [1], number: [1]]]

      input = "1 -1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [minus: [number: [1], number: [1]]]

      input = "1 - 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [minus: [number: [1], number: [1]]]

      input = " 1 - 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [minus: [number: [1], number: [1]]]

      input = " 1 - 1 "
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [minus: [number: [1], number: [1]]]
    end

    test "parse mult operation" do
      # Uso del analizador léxico en otro módulo
      input = "1*1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [mult: [number: [1], number: [1]]]

      input = "1* 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [mult: [number: [1], number: [1]]]

      input = "1 *1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [mult: [number: [1], number: [1]]]

      input = "1 * 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [mult: [number: [1], number: [1]]]

      input = " 1 * 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [mult: [number: [1], number: [1]]]

      input = " 1 * 1 "
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [mult: [number: [1], number: [1]]]
    end

    test "parse div operation" do
      # Uso del analizador léxico en otro módulo
      input = "1/1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [div: [number: [1], number: [1]]]

      input = "1/ 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [div: [number: [1], number: [1]]]

      input = "1 /1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [div: [number: [1], number: [1]]]

      input = "1 / 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [div: [number: [1], number: [1]]]

      input = " 1 / 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [div: [number: [1], number: [1]]]

      input = " 1 / 1 "
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [div: [number: [1], number: [1]]]
    end

    test "parse parenthesis" do
      # Uso del analizador léxico en otro módulo
      input = "(1/1)"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [div: [number: [1], number: [1]]]

      input = "(1+1)"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [plus: [number: [1], number: [1]]]

      input = "(1-1)"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [minus: [number: [1], number: [1]]]

      input = "(1+1) * 2"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [mult: [plus: [number: [1], number: [1]], number: [2]]]

      input = "-(1) "
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [negation: [number: [1]]]

      input = "-(1) + 3*4"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [plus: [negation: [number: [1]], mult: [number: [3], number: [4]]]]

      input = "-(1) "
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [negation: [number: [1]]]
    end

    test "parse compare operation" do
      input = "3 > 4"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [{:stric_more, [number: [3], number: [4]]}]

      input = "3 < 4"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [{:stric_less, [number: [3], number: [4]]}]

      input = "3 >= 4"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [{:more_equal, [number: [3], number: [4]]}]

      input = "3 <= 4"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [{:less_equal, [number: [3], number: [4]]}]
    end

    test "parse boolean" do
      # Uso del analizador léxico en otro módulo
      input = "true"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [boolean: [true]]

      input = "false"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [boolean: [false]]
    end

    test "parse and operation" do
      # Uso del analizador léxico en otro módulo
      input = "false and false"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [and: [boolean: [false], boolean: [false]]]

      input = "(3>4) and false"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [and: [{:stric_more, [number: [3], number: [4]]}, {:boolean, [false]}]]
    end

    test "parse or operation" do
      input = "true or true"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [or: [boolean: [true], boolean: [true]]]

      input = "trueortrue"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [or: [boolean: [true], boolean: [true]]]

      input = "trueor false"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [or: [boolean: [true], boolean: [false]]]

      input = "false ortrue"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [or: [boolean: [false], boolean: [true]]]

      input = "(3 > 4) or false"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [or: [{:stric_more, [number: [3], number: [4]]}, {:boolean, [false]}]]

      input = "(4>7) == (true or false)"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [
               equal: [
                 stric_more: [number: [4], number: ~c"\a"],
                 or: [boolean: [true], boolean: [false]]
               ]
             ]

      # input = "(3) or false"
      # {_, token, _, _, _, _} = Parser.parse(input)

      # assert token == [number: [3]]
    end

    test "parse not operation" do
      # Uso del analizador léxico en otro módulo
      input = "not true"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [not: [boolean: [true]]]

      input = "not false"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [not: [boolean: [false]]]

      input = " nottrue"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == "expected boolean while processing parenthesis or not or boolean"
    end

    test "parse negation operation" do
      input = "- 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [negation: [number: [1]]]

      input = "-1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [negation: [number: [1]]]

      input = " - 1 "
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [negation: [number: [1]]]

      input = " - 1"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [negation: [number: [1]]]

      input = "- 1 "
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [negation: [number: [1]]]
    end

    test "parse if_then statemen" do
      input = "if false then 2"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [
               if_statement: [
                 "if",
                 {:condition, [boolean: [false]]},
                 "then",
                 {:then_expression, [number: [2]]}
               ]
             ]

      input = "if false or true then 2"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [
               if_statement: [
                 "if",
                 {:condition, [or: [boolean: [false], boolean: [true]]]},
                 "then",
                 {:then_expression, [number: [2]]}
               ]
             ]

      input = "if (4>7) == (true or false) then 2"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [
               if_statement: [
                 "if",
                 {:condition,
                  [
                    equal: [
                      stric_more: [number: [4], number: ~c"\a"],
                      or: [boolean: [true], boolean: [false]]
                    ]
                  ]},
                 "then",
                 {:then_expression, [number: [2]]}
               ]
             ]

      input = "if (4>7) == (true or false) then false"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [
               if_statement: [
                 "if",
                 {:condition,
                  [
                    equal: [
                      stric_more: [number: [4], number: ~c"\a"],
                      or: [boolean: [true], boolean: [false]]
                    ]
                  ]},
                 "then",
                 {:then_expression, [boolean: [false]]}
               ]
             ]

      input = "if (4>7) == (true or false) then (4+(5*3))*5"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [
               if_statement: [
                 "if",
                 {:condition,
                  [
                    equal: [
                      stric_more: [number: [4], number: ~c"\a"],
                      or: [boolean: [true], boolean: [false]]
                    ]
                  ]},
                 "then",
                 {:then_expression,
                  [
                    mult: [
                      {:plus, [number: [4], mult: [number: [5], number: [3]]]},
                      {:number, [5]}
                    ]
                  ]}
               ]
             ]

      input = "if (4>7) == (true or false) then 2 else (4+(5*3))*5"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [
               if_statement: [
                 "if",
                 {:condition,
                  [
                    equal: [
                      stric_more: [number: [4], number: ~c"\a"],
                      or: [boolean: [true], boolean: [false]]
                    ]
                  ]},
                 "then",
                 {:then_expression, [number: [2]]},
                 {:else_expression,
                  [mult: [plus: [number: [4], mult: [number: [5], number: [3]]], number: [5]]]}
               ]
             ]
    end
  end

  describe "detect basic semantic erros correctly" do
    test "right parenthesis" do
      # Uso del analizador léxico en otro módulo
      input = "()"
      {_, token, _, _, _, _} = Parser.parse(input)
      assert token == []
    end
  end
end
