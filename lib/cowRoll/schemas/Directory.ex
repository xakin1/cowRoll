defmodule CowRoll.Directory do
  use Ecto.Schema
  import CowRoll.Utils.Functions
  import CowRoll.Schemas.Helper
  import CowRoll.File
  @root_name "Root"
  @directory_type "Directory"
  @file_type "File"
  @directory_collection "code"

  def get_attributes(params) do
    %{
      name: params["name"],
      parent_id: params["parentId"]
    }
  end

  def delete_directory(user_id, directory_id) do
    query = %{
      userId: user_id,
      id: directory_id,
      type: @directory_type
    }

    delete_files(%{user_id: user_id, directory_id: directory_id})

    deletes = Mongo.delete_one!(:mongo, @directory_collection, query)
    deletes.deleted_count
  end

  def searchParent(user_id, parent_id) do
    parent_id =
      if parent_id == nil do
        parent = get_root(user_id)
        parent["id"]
      else
        parent_id
      end

    case Mongo.find_one(:mongo, @directory_collection, %{id: parent_id}) do
      nil ->
        {:error, "parent not found"}

      directory ->
        {:ok, directory["id"]}
    end
  end

  def get_root(user_id) do
    query = %{userId: user_id, name: @root_name, type: @directory_type}

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        insert_one(user_id)

        get_root(user_id)

      directory ->
        directory
    end
  end

  def update_directory(user_id, directory_id, params) do
    query = %{
      userId: user_id,
      id: directory_id,
      type: @directory_type
    }

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        {:error, "File not found"}

      %{"_id" => existing_id} ->
        updates = get_updates(params)

        Mongo.update_one(:mongo, @directory_collection, %{_id: existing_id}, updates)
    end
  end

  @spec find_or_create_directory(any(), any(), any()) :: {:error, <<_::128>>} | {:ok, any()}
  def find_or_create_directory(user_id, name, parent_id) do
    case searchParent(user_id, parent_id) do
      {:error, reason} ->
        {:error, reason}

      {:ok, parent_id} ->
        query =
          if name not in [nil, ""] do
            #  Queremos crear un directorio
            %{userId: user_id, id: parent_id, name: name, type: @directory_type}
          else
            # Queremos insertar un fichero en un directorio
            %{userId: user_id, id: parent_id, type: @directory_type}
          end

        case Mongo.find_one(:mongo, @directory_collection, query) do
          nil ->
            directory_id = insert_one(user_id, name, parent_id)

            {:ok, directory_id}

          directory ->
            {:ok, directory["id"]}
        end
    end
  end

  def get_directory_structure(user_id) do
    directory = get_root(user_id)

    # Construye la estructura recursivamente
    build_structure(directory)
  end

  defp build_structure(directory) do
    # Recupera subdirectorios
    subdirectories =
      Mongo.find(:mongo, @directory_collection, %{
        parent_id: directory["id"],
        type: @directory_type
      })
      |> Enum.to_list()

    # Recupera archivos en el directorio actual
    files =
      Mongo.find(:mongo, @directory_collection, %{
        directory_id: directory["id"],
        type: @file_type
      })
      |> Enum.to_list()

    # Mapa de datos para el directorio actual
    %{
      id: directory["id"],
      name: directory["name"],
      type: @directory_type,
      children:
        Enum.map(files, fn file ->
          %{id: file["id"], name: file["name"], type: file["type"], content: file["content"]}
        end) ++ Enum.map(subdirectories, &build_structure/1)
    }
  end

  def insert_one(user_id, name \\ @root_name, parent_id \\ nil, type \\ @directory_type) do
    id = get_unique_id()

    Mongo.insert_one(:mongo, @directory_collection, %{
      userId: user_id,
      id: id,
      name: name,
      type: type,
      parent_id: parent_id
    })

    id
  end
end
