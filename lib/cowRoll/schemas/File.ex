defmodule CowRoll.File do
  use Ecto.Schema
  import Ecto.Changeset

  schema "files" do
    field(:userId, :integer)
    field(:name, :string)
    field(:content, :string)
    belongs_to(:directory, CowRoll.Directory)
  end

  def changeset(file, attrs) do
    file
    |> cast(attrs, [:name, :userId, :content, :directory_id])
    |> validate_required([:name, :userId, :content, :directory_id])
  end
end
