defmodule DiceRoller do
  use Dice

  defmacro __using__(_opts) do
    quote do
      import DiceRoller
    end
  end

  def roll_dices(0, _) do
    0
  end

  def roll_dices(number_of_dices, number_of_face)
      when number_of_dices > 0 and number_of_face == 0 do
    {:error, "Invalid format"}
  end

  def roll_dices(number_of_dices, number_of_face) when number_of_dices > 0 do
    roll = :rand.uniform(number_of_face)
    roll + roll_dices(number_of_dices - 1, number_of_face)
  end

  # de un input con formato 1d6 sacamos un valor entero aleatorio entre 1 y 6
  @spec roll_dice(any()) ::
          {:error, <<_::96, _::_*64>>} | {:ok, non_neg_integer() | {:error, <<_::112>>}}
  def roll_dice(input) do
    try do
      case String.contains?(input, "d") do
        true -> roll_dice_from_input(input)
        false -> {:error, "Input has a invalid notation"}
      end
    rescue
      _ -> {:error, "Invalid type"}
    end
  end

  defp roll_dice_from_input(input) do
    case parse_dice(input) do
      {:ok, number_of_dices, number_of_faces} ->
        {:ok, roll_dices(number_of_dices, number_of_faces)}

      {:error, error} ->
        {:error, error}
    end
  end
end
