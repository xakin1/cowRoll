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
end
