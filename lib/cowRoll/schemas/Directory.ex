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
      "name" => params["name"],
      "parent_id" => params["parentId"]
    }
  end

  def delete_directory(user_id, directory_id) do
    query = %{
      "userId" => user_id,
      "id" => directory_id,
      "type" => @directory_type
    }

    delete_files(%{"user_id" => user_id, "directory_id" => directory_id})

    deletes = Mongo.delete_one!(:mongo, @directory_collection, query)
    deletes.deleted_count
  end

  def get_root(user_id) do
    query = %{"userId" => user_id, "name" => @root_name, "type" => @directory_type}

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        insert_one(user_id)

        get_root(user_id)

      directory ->
        directory["id"]
    end
  end

  def update_directory(user_id, directory_id, params) do
    query = %{
      "userId" => user_id,
      "id" => directory_id,
      "type" => @directory_type
    }

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        {:error, "File not found"}

      %{"_id" => existing_id} ->
        updates = get_updates(params)

        Mongo.update_one(:mongo, @directory_collection, %{"_id" => existing_id}, updates)
    end
  end

  @spec find_directory(any(), any()) :: {:error, <<_::128>>} | {:ok, any()}
  def find_directory(user_id, parent_id) do
    # Si no existe el root se lo tenemos que crear
    if parent_id == nil do
      {:ok, get_root(user_id)}
    else
      case Mongo.find_one(:mongo, @directory_collection, %{"id" => parent_id}) do
        nil ->
          {:error, "parent not found"}

        directory ->
          {:ok, directory["id"]}
      end
    end
  end

  def get_directory(user_id, parent_id) do
    # Si no existe el root se lo tenemos que crear
    case parent_id do
      nil -> get_root(user_id)
      "" -> get_root(user_id)
      _ -> parent_id
    end

    case Mongo.find_one(:mongo, @directory_collection, %{"id" => parent_id}) do
      nil ->
        {:error, "parent not found"}

      directory ->
        {:ok, directory}
    end
  end

  def create_directory(user_id, params) do
    case Mongo.find_one(:mongo, @directory_collection, params) do
      nil ->
        insert_one(user_id, params)

      _ ->
        {:error, "A folder with that name already exists."}
    end
  end

  def get_directory_structure(user_id) do
    directory_id = get_root(user_id)
    {:ok, directory} = get_directory(user_id, directory_id)
    # Construye la estructura recursivamente
    build_structure(directory)
  end

  defp build_structure(directory) do
    # Recupera subdirectorios
    subdirectories =
      Mongo.find(:mongo, @directory_collection, %{
        "parent_id" => directory["id"],
        "type" => @directory_type
      })
      |> Enum.to_list()

    # Recupera archivos en el directorio actual
    files =
      Mongo.find(:mongo, @directory_collection, %{
        "directory_id" => directory["id"],
        "type" => @file_type
      })
      |> Enum.to_list()

    # Mapa de datos para el directorio actual
    %{
      id: directory["id"],
      name: directory["name"],
      parentId: directory["parent_id"],
      type: @directory_type,
      children:
        Enum.map(files, fn file ->
          %{
            id: file["id"],
            name: file["name"],
            type: file["type"],
            content: file["content"],
            directoryId: file["directoryId"]
          }
        end) ++ Enum.map(subdirectories, &build_structure/1)
    }
  end

  def insert_one(user_id, params \\ %{}) do
    id = get_unique_id()

    default_params = %{
      "id" => id,
      "userId" => user_id,
      "name" => @root_name,
      "type" => @directory_type
    }

    params = Map.merge(default_params, params)

    if(params["name"] == "" or params["name"] == nil) do
      {:error, "The name of the folder can't be empty."}
    else
      params =
        Map.update(params, "parent_id", nil, fn
          "" ->
            get_root(user_id)

          nil ->
            get_root(user_id)

          current_value ->
            current_value
        end)

      Mongo.insert_one(:mongo, @directory_collection, params)

      {:ok, id}
    end
  end
end
