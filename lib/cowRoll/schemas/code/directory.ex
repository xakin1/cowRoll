defmodule CowRoll.Directory do
  import CowRoll.Utils.Functions
  import CowRoll.Schemas.Helper
  import CowRollWeb.ErrorCodes
  alias CowRoll.File
  @root_name "Root"
  @directory_type "Directory"
  @file_type "File"
  @directory_collection "code"

  @parent_id "parent_id"
  @directory_id "directory_id"

  @name "name"
  @id "id"
  @user_id "user_id"
  @type_key "type"
  @mongo_id "_id"

  def get_attributes(params) do
    %{
      @name => params["name"],
      @parent_id => params["parentId"],
      @id => params["id"]
    }
  end

  defp get_parent_id(user_id, params) do
    parent_id = params[@parent_id]

    if parent_id == nil and get_name(params) != @root_name do
      get_root(user_id)
    else
      parent_id
    end
  end

  defp get_name(params) do
    params[@name]
  end

  defp get_id(params) do
    params[@id]
  end

  def set_parent_id(params, parent_id) do
    Map.merge(params, %{@parent_id => parent_id})
  end

  defp get_parent_id(params) do
    params[@parent_id]
  end

  def delete_directory(user_id, directory_id) do
    query = %{
      @user_id => user_id,
      @id => directory_id,
      @type_key => @directory_type
    }

    # Esto no me acaba de convencer, estaría mejor si esta clase no supiese formar un mapa para la clase File
    File.delete_files(%{@user_id => user_id, @directory_id => directory_id})

    deletes = Mongo.delete_one!(:mongo, @directory_collection, query)
    deletes.deleted_count
  end

  def get_root(user_id) do
    query = %{@user_id => user_id, @name => @root_name, @type_key => @directory_type}

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        insert_one(user_id)

        get_root(user_id)

      directory ->
        get_id(directory)
    end
  end

  def update_directory(user_id, params) do
    query = %{
      @user_id => user_id,
      @id => get_id(params),
      @type_key => @directory_type
    }

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        {:error, directory_not_found()}

      %{@mongo_id => existing_id} ->
        if is_descendant?(user_id, get_id(params), get_parent_id(params)) do
          {:error, parent_into_child()}
        else
          updates = get_updates(params)

          Mongo.update_one(:mongo, @directory_collection, %{@mongo_id => existing_id}, updates)
        end
    end
  end

  # Verifica si el destino es un descendiente del directorio actual
  defp is_descendant?(user_id, directory_id, parent_id) do
    {:ok, directory} = get_directory(user_id, parent_id)

    cursor = get_descendants(get_id(directory))

    Enum.any?(cursor |> Enum.to_list(), fn doc ->
      Enum.any?(doc["descendants"], fn descendant ->
        get_id(descendant) == directory_id
      end)
    end)
  end

  defp get_descendants(directory_id) do
    # filtra los documentos en la colección para encontrar el documento que coincide con el id
    aggregation_pipeline = [
      %{"$match" => %{@id => directory_id}},
      %{
        "$graphLookup" => %{
          from: @directory_collection,
          startWith: "$id",
          connectFromField: @parent_id,
          connectToField: @id,
          as: "descendants"
        }
      }
    ]

    Mongo.aggregate(:mongo, @directory_collection, aggregation_pipeline)
  end

  def find_directory(user_id, params) do
    parent_id = get_parent_id(user_id, params)

    case Mongo.find_one(:mongo, @directory_collection, %{@id => parent_id}) do
      nil ->
        {:error, parent_not_found()}

      directory ->
        {:ok, get_id(directory)}
    end
  end

  def get_directory(user_id, parent_id) do
    # Si no existe el root se lo tenemos que crear
    case parent_id do
      nil -> get_root(user_id)
      "" -> get_root(user_id)
      _ -> parent_id
    end

    case Mongo.find_one(:mongo, @directory_collection, %{@id => parent_id}) do
      nil ->
        {:error, parent_not_found()}

      directory ->
        {:ok, directory}
    end
  end

  def create_directory(user_id, params) do
    query = %{
      @parent_id => get_parent_id(user_id, params),
      @name => get_name(params),
      @type_key => @directory_type
    }

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        insert_one(user_id, params)

      _ ->
        {:error, directory_name_already_exits()}
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
        @parent_id => get_id(directory),
        @type_key => @directory_type
      })
      |> Enum.to_list()

    # Recupera archivos en el directorio actual
    files =
      Mongo.find(:mongo, @directory_collection, %{
        @directory_id => get_id(directory),
        @type_key => @file_type
      })
      |> Enum.to_list()

    # Mapa de datos para el directorio actual
    %{
      id: get_id(directory),
      name: get_name(directory),
      parentId: get_parent_id(directory),
      type: @directory_type,
      children:
        Enum.map(files, fn file ->
          %{
            id: File.get_id(file),
            name: File.get_name(file),
            type: File.get_type(file),
            content: File.get_content(file),
            contentSchema: File.get_content_schema(file),
            directoryId: File.get_directory_id(file)
          }
        end) ++ Enum.map(subdirectories, &build_structure/1)
    }
  end

  def insert_one(user_id, params \\ %{}) do
    id = get_unique_id()

    default_params = %{
      @user_id => user_id,
      @name => @root_name,
      @type_key => @directory_type
    }

    params = Map.merge(default_params, params)
    params = Map.put(params, @id, id)
    name = get_name(params)

    if(name == "" or name == nil) do
      {:error, empty_folder_name()}
    else
      params =
        Map.update(params, @parent_id, nil, fn
          "" ->
            get_root(user_id)

          nil ->
            get_root(user_id)

          current_value ->
            current_value
        end)

      params = clean_params(params)

      case Mongo.insert_one(:mongo, @directory_collection, params) do
        {:ok, _result} ->
          {:ok, id}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end
end
