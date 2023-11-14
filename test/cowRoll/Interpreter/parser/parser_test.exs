defmodule CowRoll.ParserTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "lexical error" do
    test "error missing right parenthesis" do
      input = "(3+ 2"

      try do
        result = Parser.parse(input)
        assert false
      catch
        {:error, "missing right parenthesis"} -> assert true
      end

      input = "(3+ (2 - (5+3))"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing right parenthesis"} -> assert true
      end
    end

    test "error missing left parenthesis" do
      input = "3+ 2)"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing left parenthesis"} -> assert true
      end

      input = "(3+ (2) - 5+3))"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing left parenthesis"} -> assert true
      end
    end

    test "error missing then" do
      input = "if x>5"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing then statement"} -> assert true
      end
    end

    test "two semantic error should return error missing right parenthesis" do
      input = "if (x>5"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing right parenthesis"} -> assert true
      end
    end

    test "two semantic error should return error missing argument" do
      input = "3*"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing statement"} -> assert true
      end

      input = "3-"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing statement"} -> assert true
      end

      input = "3+"

      try do
        Parser.parse(input)
        assert false
      catch
        {:error, "missing statement"} -> assert true
      end
    end
  end

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
