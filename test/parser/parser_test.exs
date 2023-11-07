defmodule CowRoll.ParserTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case

  describe "string/1" do
    test "returns :ok when attackRoll is defined" do
      # Uso del analizador léxico en otro módulo
      input = "forward 5\ndown 1\ndown 100"
      tokens = Parser.parse(input)

      assert tokens ==
               {:ok,
                [
                  {{:move, :forward}, {:number, 5}},
                  {{:move, :down}, {:number, 1}},
                  {{:move, :down}, {:number, 100}}
                ]}
    end
  end
end
