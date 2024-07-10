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

  def clean_and_merge_params(default_params, params) do
    # Convertir las claves a cadenas
    params = Enum.into(params, %{}, fn {k, v} -> {to_string(k), v} end)

    # Filtrar los pares clave-valor donde el valor es nil
    params = Enum.filter(params, fn {_, v} -> v != nil end)

    # Convertir de nuevo la lista filtrada a un mapa
    params = Enum.into(params, %{})

    # Hacer el Map.merge con default_params
    Map.merge(default_params, params)
  end
end
