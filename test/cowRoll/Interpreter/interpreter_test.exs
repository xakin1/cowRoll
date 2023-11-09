defmodule CowRoll.InterpreterTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "string/1" do
    test "returns a rolled dice" do
      # Uso del analizador léxico en otro módulo
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6")
        assert is_integer(dice)

        assert dice > 0 and dice <= 6
      end
    end

    test "returns a rolled dice plus 3" do
      # Uso del analizador léxico en otro módulo
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6 +3")
        assert is_integer(dice)

        assert dice >= 4 and dice <= 9
      end
    end

    test "returns a rolled dice minus 3" do
      # Uso del analizador léxico en otro módulo
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6 - 3")
        assert is_integer(dice)

        assert dice >= -2 and dice <= 3
      end
    end

    test "returns a rolled dice multiply 3" do
      # Uso del analizador léxico en otro módulo
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6 * 3")
        assert is_integer(dice)
        assert dice >= 3 and dice <= 18
      end
    end

    test "returns a rolled dice div 3" do
      # Uso del analizador léxico en otro módulo
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6 / 3")

        assert is_integer(dice)
        assert dice >= 0 and dice <= 2
      end
    end

    test "apply correctly order" do
      # Uso del analizador léxico en otro módulo
      number = Interpreter.eval_input("18 + 6 / 3")

      assert is_integer(number)
      assert number == 20
    end

    test "apply correctly parathesis" do
      # Uso del analizador léxico en otro módulo
      number = Interpreter.eval_input("18 / ((3 + 6) * 2)")

      assert is_integer(number)
      assert number == 1
    end
  end
end
