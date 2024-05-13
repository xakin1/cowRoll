defmodule TypesUtils do
  @string "String"
  @boolean "Boolean"
  @integer "Integer"
  @map "Map"
  @list "List"

  def get_type(value) when is_binary(value), do: @string
  def get_type(value) when is_boolean(value), do: @boolean
  def get_type(value) when is_integer(value), do: @integer

  def get_type(:string), do: @string
  def get_type(:boolean), do: @boolean
  def get_type(:number), do: @integer
  def get_type(:map), do: @map
  def get_type(:list), do: @list
  def get_type(:name), do: fresh_type()

  def get_type_boolean, do: @boolean
  def get_type_integer, do: @integer
  def get_type_string, do: @string
  def get_type_map, do: @map
  def get_type_list, do: @list

  def is_list?(type) do
    case type do
      @list -> true
      _ -> false
    end
  end

  def fresh_type() do
    :"t#{:erlang.unique_integer([:positive, :monotonic])}"
  end
end
