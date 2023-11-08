defmodule CowRoll.ParserTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "string/1" do
    test "returns :ok when attackRoll is defined" do
      # Uso del analizador léxico en otro módulo
      input = "1d5"
      tokens = Parser.parse(input)

      assert tokens ==
               {:ok, {:dice, "1d5"}}
    end
  end
end
