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

      input = "( 1+1)"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [plus: [number: [1], number: [1]]]

      input = "( 1-1 )"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [minus: [number: [1], number: [1]]]

      input = "(1 + 1 ) * 2"
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

    test "parse boolean" do
      # Uso del analizador léxico en otro módulo
      input = "true"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [boolean: [true]]

      input = "true "
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [boolean: [true]]

      input = " false"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [boolean: [false]]

      input = " false "
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
      # Uso del analizador léxico en otro módulo
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

      input = "(3) or false"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [number: [3]]
    end

    test "parse not operation" do
      # Uso del analizador léxico en otro módulo
      input = "not true"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [not: [boolean: [true]]]

      input = "notfalse"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [not: [boolean: [false]]]

      input = " nottrue"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [not: [boolean: [true]]]

      input = "notfalse "
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [not: [boolean: [false]]]
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
  end

  # describe "detect conditionals correctly" do
  #   input = "if false or (3>5) then 2"
  #   {_, token, _, _, _, _} = Parser.parse(input)

  #   assert token == [
  #            if_then: [
  #              condition: [or: [boolean: [false], stric_more: [number: [3], number: [5]]]],
  #              then_expr: [number: [2]]
  #            ]
  #          ]

  #   input = "if (3>6) and (4==4) then 2 else 3"
  #   {_, token, _, _, _, _} = Parser.parse(input)

  #   assert token == [
  #            if_then_else: [
  #              if_then: [
  #                condition: [
  #                  and: [
  #                    stric_more: [number: [3], number: [6]],
  #                    equal: [number: [4], number: [4]]
  #                  ]
  #                ],
  #                then_expr: [number: [2]]
  #              ],
  #              else_expr: [number: [3]]
  #            ]
  #          ]
  # end
end
