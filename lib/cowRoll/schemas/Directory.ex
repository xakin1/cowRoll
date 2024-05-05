defmodule CowRoll.Directory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "directories" do
    field(:name, :string)
    field(:userId, :integer)
    belongs_to(:parent, CowRoll.Directory, foreign_key: :parent_id)
    has_many(:subdirectories, CowRoll.Directory, foreign_key: :parent_id)
    has_many(:files, CowRoll.File)
  end

  def changeset(directory, attrs) do
    directory
    |> cast(attrs, [:name, :userId, :parent_id])
    |> validate_required([:name, :userId])
  end
end
