defmodule TypesUtils do
  def get_type(value) when is_binary(value) do
    "String"
  end

  def get_type(value) when is_boolean(value) do
    "Boolean"
  end

  def get_type(value) when is_integer(value) do
    "Integer"
  end

  def get_type(value) when is_map(value) do
    "Map"
  end

  def get_type(value) when is_list(value) do
    "List"
  end
end
