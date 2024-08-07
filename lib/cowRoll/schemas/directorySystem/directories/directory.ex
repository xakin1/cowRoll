defmodule CowRoll.Directory do
  import CowRoll.Utils.Functions
  import CowRoll.Schemas.Helper
  import CowRollWeb.ErrorCodes
  alias CowRoll.File
  @root_name "Root"
  @file_system "file_system"

  @parent_id "parent_id"
  @directory_id "directory_id"
  @directory_type "Directory"

  @name "name"
  @id "id"
  @user_id "user_id"
  @type_key "type"
  @mongo_id "_id"
  @rol_type "Rol"

  @type_mappings %{
    @directory_type => CowRoll.Directory,
    @rol_type => CowRoll.Rol
  }

  defmacro __using__(_) do
    quote do
      @behaviour CowRoll.DirectoryBehaviour

      def get_base_attributes(params), do: CowRoll.Directory.get_attributes(params)
      def get_directory_type(), do: CowRoll.Directory.get_directory_type()
      def get_id_key(), do: CowRoll.Directory.get_id_key()
      def get_user_id_key(), do: CowRoll.Directory.get_user_id_key()
      def get_parent_id_key(), do: CowRoll.Directory.get_parent_id_key()
      def get_name_key(), do: CowRoll.Directory.get_name_key()
      def get_type_key(), do: CowRoll.Directory.get_type_key()
      def get_id(params), do: CowRoll.Directory.get_id(params)
      def get_parent_id(params), do: CowRoll.Directory.get_parent_id(params)

      def get_safe_parent_id(user_id, params),
        do: CowRoll.Directory.get_safe_parent_id(user_id, params)

      def get_name(params), do: CowRoll.Directory.get_name(params)
      def get_type(params), do: CowRoll.Directory.get_type(params)
      def find_directory(user_id, params), do: CowRoll.Directory.find_directory(user_id, params)

      def insert_directory(user_id, params),
        do: CowRoll.Directory.insert_directory(user_id, params)

      def delete_directory(user_id, id), do: CowRoll.Directory.delete_directory(user_id, id)

      def get_directory(user_id, parent_id),
        do: CowRoll.Directory.get_directory(user_id, parent_id)

      def get_directory_structure(params), do: CowRoll.Directory.get_directory_structure(params)

      def update_directory(user_id, params),
        do: CowRoll.Directory.update_directory(user_id, params)
    end
  end

  def get_attributes(params) do
    %{
      @name => params["name"],
      @parent_id => params["parentId"],
      @id => params["id"],
      @type_key => params["type"]
    }
  end

  def get_directory_type() do
    @directory_type
  end

  def get_id_key() do
    @id
  end

  def get_user_id_key() do
    @user_id
  end

  def get_parent_id_key() do
    @parent_id
  end

  def get_name_key() do
    @name
  end

  def get_type_key() do
    @type_key
  end

  def get_root(user_id) do
    query = %{@user_id => user_id, @name => @root_name}

    case Mongo.find_one(:mongo, @file_system, query) do
      nil ->
        insert_directory(user_id)

        get_root(user_id)

      directory ->
        get_id(directory)
    end
  end

  def get_safe_parent_id(user_id, params) do
    parent_id = params[@parent_id]

    if parent_id == nil and get_name(params) != @root_name do
      get_root(user_id)
    else
      parent_id
    end
  end

  def get_name(params) do
    params[@name]
  end

  def get_type(params) do
    params[@type_key]
  end

  def get_id(params) do
    params[@id]
  end

  def set_parent_id(params, parent_id) do
    Map.merge(params, %{@parent_id => parent_id})
  end

  def get_parent_id(params) do
    params[@parent_id]
  end

  def delete_directory(user_id, directory_id) do
    File.delete_files(%{@user_id => user_id, @directory_id => directory_id})

    deletes =
      Mongo.delete_one!(:mongo, @file_system, %{
        @id => directory_id
      })

    deletes.deleted_count
  end

  def update_directory(user_id, params) do
    query = %{
      @user_id => user_id,
      @id => get_id(params),
      @type_key => get_type(params)
    }

    case Mongo.find_one(:mongo, @file_system, query) do
      nil ->
        {:error, directory_not_found()}

      %{@mongo_id => existing_id} ->
        case is_descendant?(user_id, get_id(params), get_parent_id(params)) do
          true ->
            {:error, parent_into_child()}

          false ->
            updates = get_updates(params)

            Mongo.update_one(:mongo, @file_system, %{@mongo_id => existing_id}, updates)

          {:error, error} ->
            {:error, error}
        end
    end
  end

  # Verifica si el destino es un descendiente del directorio actual
  defp is_descendant?(user_id, directory_id, parent_id) do
    case get_directory(user_id, parent_id) do
      {:ok, directory} ->
        cursor = get_descendants(get_id(directory))

        Enum.any?(cursor |> Enum.to_list(), fn doc ->
          Enum.any?(doc["descendants"], fn descendant ->
            get_id(descendant) == directory_id
          end)
        end)

      {:error, error} ->
        {:error, error}
    end
  end

  defp get_descendants(directory_id) do
    # filtra los documentos en la colección para encontrar el documento que coincide con el id
    aggregation_pipeline = [
      %{"$match" => %{@id => directory_id}},
      %{
        "$graphLookup" => %{
          from: @file_system,
          startWith: "$id",
          connectFromField: @parent_id,
          connectToField: @id,
          as: "descendants"
        }
      }
    ]

    Mongo.aggregate(:mongo, @file_system, aggregation_pipeline)
  end

  def find_directory(user_id, params) do
    parent_id = get_safe_parent_id(user_id, params)

    case Mongo.find_one(:mongo, @file_system, %{@id => parent_id}) do
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

    case Mongo.find_one(:mongo, @file_system, %{@id => parent_id}) do
      nil ->
        {:error, parent_not_found()}

      directory ->
        {:ok, directory}
    end
  end

  def create_directory(user_id, params) do
    parent_id = get_safe_parent_id(user_id, params)

    query = %{
      @parent_id => parent_id,
      @name => get_name(params),
      @type_key => @directory_type
    }

    params = set_parent_id(params, parent_id)

    case Mongo.find_one(:mongo, @file_system, query) do
      nil ->
        insert_directory(user_id, params)

      _ ->
        {:error, directory_name_already_exits()}
    end
  end

  def base_create_directory(user_id, params) do
    type = get_type(params)
    call_function(type, :create_directory, [user_id, params])
  end

  def base_get_attributes(params) do
    type = get_type(params)
    call_function(type, :get_attributes, [params])
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
      Mongo.find(:mongo, @file_system, %{
        @parent_id => get_id(directory)
      })
      |> Enum.to_list()

    # Recupera archivos en el directorio actual
    files = File.get_files(%{@directory_id => get_id(directory)})

    # Mapa de datos para el directorio actual
    Map.merge(default_directory_to_json(directory), %{
      children:
        Enum.map(files, fn file ->
          File.default_file_to_json(file)
        end) ++ Enum.map(subdirectories, &build_structure/1)
    })
  end

  def directory_to_json(directory) do
    if(directory != nil) do
      %{
        id: get_id(directory),
        name: get_name(directory),
        parentId: get_parent_id(directory),
        type: @directory_type
      }
    else
      %{}
    end
  end

  defp call_function(type, func_name, args) do
    case Map.get(@type_mappings, type) do
      nil -> apply(CowRoll.Directory, func_name, args)
      module -> apply(module, func_name, args)
    end
  end

  def default_directory_to_json(directory) do
    type = get_type(directory)
    call_function(type, :directory_to_json, [directory])
  end

  def insert_directory(user_id, params \\ %{}) do
    id = get_unique_id()

    default_params = %{
      @user_id => user_id,
      @name => @root_name,
      @type_key => @directory_type
    }

    params = clean_and_merge_params(default_params, params)
    params = Map.put(params, @id, id)
    name = get_name(params)

    if(name == "" or name == nil) do
      {:error, empty_folder_name()}
    else
      params =
        if(name != @root_name) do
          parent_id = Map.get(params, @parent_id, get_root(user_id))

          Map.put(params, @parent_id, parent_id)
        else
          params
        end

      params = clean_params(params)

      case Mongo.insert_one(:mongo, @file_system, params) do
        {:ok, _result} ->
          {:ok, id}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end
end
