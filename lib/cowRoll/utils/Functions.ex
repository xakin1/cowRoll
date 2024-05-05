defmodule CowRoll.Utils.Functions do
  @spec get_unique_id() :: integer()
  def get_unique_id do
    :erlang.unique_integer([:positive, :monotonic])
  end
end
