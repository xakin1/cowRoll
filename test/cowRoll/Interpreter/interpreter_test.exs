defmodule CowRoll.InterpreterTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "string/1" do
    test "returns :ok when attackRoll is defined" do
      # Uso del analizador léxico en otro módulo
      input = "1d6"

      for _ <- 1..100 do
        {{:ok, dice}} = Interpreter.eval_input(input)

        assert dice > 0 && dice <= 6
      end
    end
  end
end
