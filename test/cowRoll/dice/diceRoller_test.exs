defmodule CowRoll.DiceRollTest do
  # Importa ExUnit.Case para definir pruebas
  use ExUnit.Case
  use DiceRoller

  describe "roll_dices/2" do
    test "returns 0 when number_of_dices is 0" do
      assert roll_dices(0, 6) == 0
    end

    test "invalid format input" do
      assert roll_dices(1, 0) == {:error, "Invalid format"}
    end

    test "returns a valid dice roll" do
      number_of_dices = 2
      number_of_faces = 6
      dice = roll_dices(number_of_dices, number_of_faces)

      assert is_integer(dice)
      assert dice > 0
      assert dice <= number_of_dices * number_of_faces
    end
  end

  describe "roll_dice/1" do
    test "returns a valid if is max value" do
      {result, dice} = roll_dice("2d20")
      assert result == :ok
      assert dice > 0
      assert dice <= 2 * 20
    end

    test "returns a valid dice roll" do
      {result, dice} = roll_dice("2d20")
      assert result == :ok
      assert dice > 0
      assert dice <= 2 * 20
    end

    test "Invalid input" do
      result = roll_dice("xdy")
      assert result == {:error, "Invalid input format"}
    end

    test "Invalid notation" do
      result = roll_dice("f")
      assert result == {:error, "Input has a invalid notation"}
    end

    test "Invalid type" do
      result = roll_dice(2)
      assert result == {:error, "Invalid type"}
    end

    test "null value" do
      result = roll_dice(nil)
      assert result == {:error, "Invalid type"}
    end

    test "void value" do
      result = roll_dice("")
      assert result == {:error, "Input has a invalid notation"}
    end

    test "negative number of dices" do
      result = roll_dice("-2d6")
      assert result == {:error, "Invalid type"}
    end

    test "negative number of faces" do
      result = roll_dice("2d-6")
      assert result == {:error, "Invalid type"}
    end
  end
end
