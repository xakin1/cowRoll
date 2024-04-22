defmodule CowRoll.Interpreter.Parser.SintaxAnalayzerTest do
  use ExUnit.Case

  describe "errors" do
    test "missing right parenthesis" do
      input = "(3+1"

      assert_raise(GrammarError, "Error: Missing ')' on line 1", fn ->
        Parser.parse(input)
      end)
    end

    test "unexpected error" do
      input = "
      {a: [1,2,3] d: {f: 'c'} e: 2}"

      assert_raise(GrammarError, "Unexpected error at line 2.", fn ->
        Parser.parse(input)
      end)
    end

    test "missing coma in list" do
      input = "[1 2]"
      result = Parser.parse(input)

      assert result == {:ok, {:list, {{:number, 1, 1}, {:number, 2, 1}}}}
    end

    test "bad assignament" do
      input = "1=2"

      assert_raise(
        GrammarError,
        "Error at line 1: Assignment can only be done to variables.",
        fn ->
          Parser.parse(input)
        end
      )
    end

    test "equal with expressions" do
      input = "if true then true end <= if false then false end"

      assert_raise(
        GrammarError,
        "Error at line 1: Expression can only be done with variables or constants.",
        fn ->
          Parser.parse(input)
        end
      )
    end

    test "equal with constant and expressions" do
      input = "3 + if false then false end"

      assert_raise(
        GrammarError,
        "Error at line 1: Expression can only be done with variables or constants.",
        fn ->
          Parser.parse(input)
        end
      )
    end

    test "equal with expressions and constant " do
      input = "if false then false end * 3"

      assert_raise(
        GrammarError,
        "Error at line 1: Expression can only be done with variables or constants.",
        fn ->
          Parser.parse(input)
        end
      )
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

    test "missing right  bracket" do
      input = "[1"

      assert_raise(GrammarError, "Error: Missing ']' on line 1", fn ->
        Parser.parse(input)
      end)
    end

    test "missing left bracket" do
      input = "
      1]"

      assert_raise(GrammarError, "Error: Missing '[' on line 2", fn ->
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
