defmodule CowRoll.ParserTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "string/1" do
    test "parse minus operation" do
      # Uso del analizador léxico en otro módulo
      input = "1-1"
      tokens = Parser.parse(input)

      assert tokens == {:ok, [1, "-", 1], "", %{}, {1, 0}, 3}
    end

    test "check if store unparse chars" do
      # Uso del analizador léxico en otro módulo
      input = "1-1 b"
      tokens = Parser.parse(input)

      assert tokens == {:ok, [1, "-", 1], " b", %{}, {1, 0}, 3}
    end

    test "check plus operation" do
      # Uso del analizador léxico en otro módulo
      input = "1 +1 b"
      tokens = Parser.parse(input)

      assert tokens == {:ok, [1, "+", 1], " b", %{}, {1, 0}, 4}
    end

    test "check mult operation" do
      # Uso del analizador léxico en otro módulo
      input = "1 * 1"
      tokens = Parser.parse(input)

      assert tokens == {:ok, [1, "*", 1], "", %{}, {1, 0}, 5}
    end

    test "check div operation" do
      # Uso del analizador léxico en otro módulo
      input = "1 / 1"
      tokens = Parser.parse(input)

      assert tokens == {:ok, [1, "/", 1], "", %{}, {1, 0}, 5}
    end

    test "check pow operation" do
      # Uso del analizador léxico en otro módulo
      input = "1^ 1"
      tokens = Parser.parse(input)

      assert tokens == {:ok, [1, "^", 1], "", %{}, {1, 0}, 4}
    end

    test "check - one operation" do
      # Uso del analizador léxico en otro módulo
      input = "-1"
      tokens = Parser.parse(input)

      assert tokens == {:ok, ["-", 1], "", %{}, {1, 0}, 2}
    end

    test "check + one operation" do
      # Uso del analizador léxico en otro módulo
      input = "+ 1"
      tokens = Parser.parse(input)

      assert tokens == {:ok, ["+", 1], "", %{}, {1, 0}, 3}
    end

    test "check and operation" do
      # Uso del analizador léxico en otro módulo
      input = "true and false"
      {result, parsed, no_parsed, _, _, _} = Parser.parse(input)

      assert result == :ok
      assert parsed == ["true", "and", "false"]
      assert no_parsed == ""
    end

    test "check or operation" do
      # Uso del analizador léxico en otro módulo
      input = "true or false"
      {result, parsed, no_parsed, _, _, _} = Parser.parse(input)

      assert result == :ok
      assert parsed == ["true", "or", "false"]
      assert no_parsed == ""
    end

    test "check or operation" do
      # Uso del analizador léxico en otro módulo
      input = "true or false"
      {result, parsed, no_parsed, _, _, _} = Parser.parse(input)

      assert result == :ok
      assert parsed == ["true", "or", "false"]
      assert no_parsed == ""
    end
  end
end
