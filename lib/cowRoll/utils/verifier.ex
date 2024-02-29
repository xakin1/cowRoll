defmodule Verifier do
  def are_all_different(ids) do
    # Transformamos la lista en un conjunto, ya que en estos no puede haber objetos repetidos
    ids_set = MapSet.new(ids)

    length(ids) == Enum.count(ids_set)
  end
end
