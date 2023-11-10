defmodule CowRoll.InterpreterTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "string/1" do
    test "returns a rolled dice" do
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6")
        assert is_integer(dice)

        assert dice > 0 and dice <= 6
      end
    end

    test "should return a negative" do
      try do
        result = Interpreter.eval_input("- 1d6")
        assert result < 0
      catch
        {:error, _} -> assert false
      end
    end

    test "should do a pow" do
      try do
        result = Interpreter.eval_input("2^3")
        assert 8 == result
      catch
        {:error, _} -> assert false
      end
    end

    test "should return an (ArithmeticError) bad argument in arithmetic expression" do
      try do
        Interpreter.eval_input("2^-3")
        assert false
      rescue
        error ->
          assert error == %ArithmeticError{message: "bad argument in arithmetic expression"}
      end
    end

    test "pow with exponent 0 should return 1" do
      try do
        result = Interpreter.eval_input("2^0")
        assert 1 == result
      rescue
        _ -> assert false
      end
    end

    test "pow with negative base should return -8" do
      try do
        result = Interpreter.eval_input("-2^3")
        assert -8 == result
      rescue
        _ -> assert false
      end
    end

    test "pow with a complex expresion in the exponent" do
      for _ <- 1..100 do
        try do
          result = Interpreter.eval_input("2^((1d6 +3) * 3)")
          assert result > 64
        rescue
          _ -> assert false
        end
      end
    end

    test "returns a rolled dice plus 3" do
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6 +3")
        assert is_integer(dice)

        assert dice >= 4 and dice <= 9
      end
    end

    test "returns a rolled dice minus 3" do
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6 - 3")
        assert is_integer(dice)

        assert dice >= -2 and dice <= 3
      end
    end

    test "returns a rolled dice multiply 3" do
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6 * 3")
        assert is_integer(dice)
        assert dice >= 3 and dice <= 18
      end
    end

    test "returns a rolled dice div 3" do
      for _ <- 1..100 do
        dice = Interpreter.eval_input("1d6 / 3")

        assert is_integer(dice)
        assert dice >= 0 and dice <= 2
      end
    end

    test "apply correctly order and ignore the space" do
      number = Interpreter.eval_input("18 \n + 6 / \s 3")

      assert is_integer(number)
      assert number == 20
    end

    test "apply correctly order" do
      number = Interpreter.eval_input("18 + 6 / 3")

      assert is_integer(number)
      assert number == 20
    end

    test "apply correctly parathesis" do
      number = Interpreter.eval_input("18 / ((3 + 6) * 2)")

      assert is_integer(number)
      assert number == 1
    end

    test "should apply correctly the negative" do
      number = Interpreter.eval_input("-18 / ((3 + 6) * 2)")

      assert is_integer(number)
      assert number == -1
    end

    test "should apply correctly the negative with parenthesis" do
      number = Interpreter.eval_input("(-(3 + 6) * 2)")

      assert is_integer(number)
      assert number == -18
    end

    test "should apply correctly the negative and return a positive number" do
      number = Interpreter.eval_input("-18 / -((3 + 6) * 2)")

      assert is_integer(number)
      assert number == 1
    end
  end
end
