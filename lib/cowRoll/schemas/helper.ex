defmodule CowRoll.Schemas.Helper do
  def get_updates(attrs) do
    Enum.reduce(attrs, %{}, fn {key, value}, acc ->
      if value != nil and value != "" do
        set_map = Map.update(acc["$set"] || %{}, key, value, fn _old -> value end)
        Map.put(acc, "$set", set_map)
      else
        acc
      end
    end)
  end

  def clean_params(attrs) do
    Enum.reduce(attrs, %{}, fn
      {_key, nil}, acc -> acc
      {key, value}, acc -> Map.put(acc, key, value)
    end)
  end
end
