defmodule CowRoll.Code do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger

  use ExUnit.CaseTemplate


  @primary_key {:id, :binary_id, autogenerate: true}  # the id maps to uuid
  schema "code" do
    field :user_id, :integer
    field :code,    :string
  end

  def changeset_new_user(user, params \\ %{}) do
    params = scrub_params(params)  # change "" to nil
    user
      |> cast(params, [:user_id, :code])
  end

  defp scrub_params(params) do
    Enum.reduce(params, %{}, fn {k, v}, acc ->
      Map.put(acc, k, (if v == "", do: nil, else: v))
    end)
  end
end
