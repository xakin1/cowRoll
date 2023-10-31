defmodule Dice do
  defmacro __using__(_opts) do
    quote do
      import Dice
    end
  end

  @base 10

  def separate_dices(dices) do
    Enum.flat_map(dices, fn dice ->
      case parse_dice(dice["dice"]) do
        {:ok, number_of_dices, number_of_faces} ->
          dice_aux = %{
            "dice" => to_dice(1, number_of_faces),
            "dmgType" => dice["dmgType"]
          }

          for _ <- 1..number_of_dices, do: dice_aux

        {:error, error} ->
          {:error, error}
      end
    end)
  end

  def to_dice(number_of_dices, number_of_faces) do
    to_string(number_of_dices) <> "d" <> to_string(number_of_faces)
  end

  @spec parse_dice(binary()) :: {:error, <<_::160>>} | {:ok, integer(), integer()}
  def parse_dice(input) do
    [x, y] = String.split(input, "d")

    try do
      number_of_dices = String.to_integer(x, @base)
      number_of_faces = String.to_integer(y, @base)
      {:ok, number_of_dices, number_of_faces}
    rescue
      _ -> {:error, "Invalid input format"}
    end
  end
end
