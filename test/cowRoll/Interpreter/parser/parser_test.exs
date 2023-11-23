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

      input = "(1 * 1 )"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [mult: [number: [1], number: [1]]]
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
      input = "trueandtrue"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [and: [boolean: [true], boolean: [true]]]

      input = "trueand false"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [and: [boolean: [true], boolean: [false]]]

      input = "false andtrue"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [and: [boolean: [false], boolean: [true]]]

      input = "false and false"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [and: [boolean: [false], boolean: [false]]]
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

      input = "false or false"
      {_, token, _, _, _, _} = Parser.parse(input)

      assert token == [or: [boolean: [false], boolean: [false]]]
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

  describe "detect conditionals correctly" do
    input = "if 1+2/3 then 2"
    {_, token, _, _, _, _} = Parser.parse(input)

    assert token == [
             if_then: [
               {:condition, [plus: [number: [1], div: [number: [2], number: [3]]]]},
               {:then_expr, [number: [2]]}
             ]
           ]

    input = "if 1+2/3 then 2 else 3"
    {_, token, _, _, _, _} = Parser.parse(input)

    assert token == [
             if_then_else: [
               {:if_then,
                [
                  {:condition, [plus: [number: [1], div: [number: [2], number: [3]]]]},
                  {:then_expr, [number: [2]]}
                ]},
               {:else_expr, [number: [3]]}
             ]
           ]
  end

  describe "detect gramatical errors correctly" do
  end
end
