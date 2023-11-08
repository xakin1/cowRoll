defmodule CowRoll.InterpreterTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "string/1" do
    test "returns :ok when attackRoll is defined" do
      # Uso del analizador léxico en otro módulo
      input = "forward 5\ndown 1\ndown 100"
      tokens = Interpreter.eval_input(input)

      assert tokens == {5, 101}
    end
  end
end
