defmodule CowRoll.Interpreter.Parser.SintaxAnalayzerTest do
  use ExUnit.Case

  describe "errors" do
    test "missing right parenthesis" do
      input = "(3+1"

      assert_raise(GrammarError, "Error: Missing ')' on line 1", fn ->
        Parser.parse(input)
      end)
    end

    test "missing left parenthesis" do
      input = "3+1)"

      assert_raise(GrammarError, "Error: Missing '(' on line 1", fn ->
        Parser.parse(input)
      end)
    end

    test "missing right curly bracket" do
      input = "{3: 1"

      assert_raise(GrammarError, "Error: Missing '}' on line 1", fn ->
        Parser.parse(input)
      end)
    end

    test "missing left curly bracket" do
      input = "
      3: 1}"

      assert_raise(GrammarError, "Error: Missing '{' on line 2", fn ->
        Parser.parse(input)
      end)
    end

    test "missing end statements with if" do
      input = "if x then
      3"

      assert_raise(GrammarError, "Error: Missing 'end' for 'if' on line 1", fn ->
        Parser.parse(input)
      end)
    end

    test "missing end statements with for" do
      input = "for y <- x do 3"

      assert_raise(GrammarError, "Error: Missing 'end' for 'for' on line 1", fn ->
        Parser.parse(input)
      end)
    end

    test "missing end statements with functions" do
      input = "function hola() do x +3"

      assert_raise(GrammarError, "Error: Missing 'end' for 'function hola' on line 1", fn ->
        Parser.parse(input)
      end)
    end

    test "missing end statements with nested blocks" do
      input = "if true then
        for y <- x do 3
        end"

      assert_raise(GrammarError, "Error: Missing 'end' for 'for' on line 2", fn ->
        Parser.parse(input)
      end)
    end

    test "end without block" do
      input = "x+3
      end"

      assert_raise(GrammarError, "Error: Unexpected 'end' on line 2", fn ->
        Parser.parse(input)
      end)
    end
  end
end
