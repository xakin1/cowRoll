defmodule CowRoll.Code do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger

  use ExUnit.CaseTemplate

  # the id maps to uuid
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "code" do
    field(:userId, :integer)
    field(:fileName, :string)
    field(:code, :string)
  end

  def changeset_new_file(file, params \\ %{}) do
    # change "" to nil
    params = scrub_params(params)

    file
    |> cast(params, [:userId, :code, :fileName])
  end

  defp scrub_params(params) do
    Enum.reduce(params, %{}, fn {k, v}, acc ->
      Map.put(acc, k, if(v == "", do: nil, else: v))
    end)
  end
end
