defmodule Dice do
  defmacro __using__(_opts) do
    quote do
      import Dice
    end
  end

  @base 10

  # Dado un dado con formato 1d6 te devuelve 1,6
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
