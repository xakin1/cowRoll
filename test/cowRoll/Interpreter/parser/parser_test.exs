defmodule CowRoll.ParserTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "string/1" do
    test "number minus number" do
      # Uso del analizador léxico en otro módulo
      input = "5 - 5"
      tokens = Parser.parse(input)

      assert tokens ==
               {:ok, {:minus, {:number, 5}, {:number, 5}}}
    end

    test "plus dice with a number" do
      # Uso del analizador léxico en otro módulo
      input = "5 + 1d5"
      tokens = Parser.parse(input)

      assert tokens ==
               {:ok, {:plus, {:number, 5}, {:dice, "1d5"}}}
    end

    test "mult dice with a parentesis number" do
      # Uso del analizador léxico en otro módulo
      input = "(5 + 3) * 1d5"
      tokens = Parser.parse(input)

      assert tokens ==
               {:ok, {:mult, {:plus, {:number, 5}, {:number, 3}}, {:dice, "1d5"}}}
    end

    test "div dice and multi a number with a parentesis" do
      # Uso del analizador léxico en otro módulo
      input = "(5 + 3) * 1d5 / 3"
      tokens = Parser.parse(input)

      assert tokens ==
               {:ok,
                {:mult, {:plus, {:number, 5}, {:number, 3}},
                 {:divi, {:dice, "1d5"}, {:number, 3}}}}
    end
  end
end
