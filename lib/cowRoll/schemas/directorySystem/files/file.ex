defmodule CowRoll.File do
  @moduledoc """
  Módulo base para manejar archivos genéricos en MongoDB.
  """

  import CowRoll.Utils.Functions
  import CowRoll.Schemas.Helper
  import CowRollWeb.ErrorCodes
  import CowRollWeb.SuccesCodes

  @type_key "type"
  @user_id "user_id"
  @id "id"
  @directory_id "directory_id"
  @name "name"
  @file_system "file_system"
  @code_type "Code"
  @type_key "type"
  @sheet_type "Sheet"
  @content "content"
  @mongo_id "_id"
  @type_key "type"

  @type_mappings %{
    @code_type => CowRoll.Code,
    @sheet_type => CowRoll.Sheet
  }
  defmacro __using__(_) do
    quote do
      @behaviour CowRoll.FileBehaviour

      def get_base_attributes(params), do: CowRoll.File.get_base_attributes(params)
      def get_id(params), do: CowRoll.File.get_id(params)
      def get_directory_id(params), do: CowRoll.File.get_directory_id(params)
      def get_name(params), do: CowRoll.File.get_name(params)
      def get_type(params), do: CowRoll.File.get_type(params)
      def get_content(params), do: CowRoll.File.get_content(params)
      def find_file(user_id, params), do: CowRoll.File.find_file(user_id, params)
      def insert_file(user_id, params), do: CowRoll.File.insert_file(user_id, params)
      def delete_file(user_id, id), do: CowRoll.File.delete_file(user_id, id)
      def get_file(user_id, id), do: CowRoll.File.get_file(user_id, id)
      def get_files(params), do: CowRoll.File.get_files(params)
      def update_file(user_id, params), do: CowRoll.File.update_file(user_id, params)
      def default_file_to_json(file), do: CowRoll.File.default_file_to_json(file)

      def update_directory_id(params, directory_id),
        do: CowRoll.File.update_directory_id(params, directory_id)

      def set_directory_id(params, directory_id),
        do: CowRoll.File.set_directory_id(params, directory_id)
    end
  end

  def get_base_attributes(params) do
    %{
      @name => params["name"],
      @content => params["content"],
      @directory_id => params["directoryId"],
      @id => params["id"],
      @type_key => params["type"]
    }
  end

  @spec get_id(nil | maybe_improper_list() | map()) :: any()
  def get_id(params) do
    params[@id]
  end

  @spec get_directory_id(nil | maybe_improper_list() | map()) :: any()
  def get_directory_id(params) do
    params[@directory_id]
  end

  def get_name(params) do
    params[@name]
  end

  def get_type(params) do
    params[@type_key]
  end

  def get_content(params) do
    params[@content]
  end

  def insert_file(user_id, params) do
    id = get_unique_id()
    params = clean_params(params)
    name = get_name(params)
    directory_id = get_directory_id(params)
    type = get_type(params)

    if name == "" or name == nil do
      {:error, empty_file_name()}
    else
      if directory_id == "" or directory_id == nil do
        {:error, parent_not_found()}
      else
        query = %{
          @user_id => user_id,
          @directory_id => directory_id,
          @name => name,
          @type_key => type
        }

        case Mongo.find_one(:mongo, @file_system, query) do
          nil ->
            default_params = %{
              @user_id => user_id
            }

            params = Enum.into(params, %{}, fn {k, v} -> {to_string(k), v} end)
            params = Map.merge(default_params, params)
            params = Map.put(params, @id, id)

            case Mongo.insert_one(:mongo, @file_system, params) do
              {:ok, _result} ->
                {:ok, id}

              {:error, reason} ->
                {:error, reason}
            end

          _ ->
            {:error, file_name_already_exits()}
        end
      end
    end
  end

  def find_file(user_id, params) do
    parent_id = get_directory_id(params)

    case Mongo.find_one(:mongo, @file_system, %{@user_id => user_id, @id => parent_id}) do
      nil ->
        {:error, parent_not_found()}

      file ->
        {:ok, get_id(file)}
    end
  end

  def get_files(params) do
    Mongo.find(:mongo, @file_system, params) |> Enum.to_list()
  end

  def update_file(user_id, params) do
    # Construye el query para buscar el documento
    query = %{
      @user_id => user_id,
      @id => get_id(params)
    }

    # Encuentra el documento que necesitas actualizar
    case Mongo.find_one(:mongo, @file_system, query) do
      nil ->
        {:error, file_not_found()}

      %{@mongo_id => existing_id} ->
        updates = get_updates(params)

        result = Mongo.update_one(:mongo, @file_system, %{@mongo_id => existing_id}, updates)

        case result do
          {:ok, _} ->
            {:ok, file_updated()}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  def delete_file(user_id, file_id) do
    query = %{
      @user_id => user_id,
      @id => file_id
    }

    deletes = Mongo.delete_one!(:mongo, @file_system, query)
    deletes.deleted_count
  end

  def get_file(user_id, id) do
    query = %{
      @user_id => user_id,
      @id => id
    }

    file = Mongo.find_one(:mongo, @file_system, query)

    default_file_to_json(file)
  end

  def update_directory_id(params, directory_id) do
    set_directory_id(params, directory_id)
  end

  def set_directory_id(params, directory_id) do
    Map.merge(params, %{@directory_id => directory_id})
  end

  def delete_files(params) do
    case Mongo.delete_many(:mongo, @file_system, params) do
      {:ok, deletes} -> deletes.deleted_count
      _ -> 0
    end
  end

  defp call_function(type, func_name, args) do
    case Map.get(@type_mappings, type) do
      nil -> %{}
      module -> apply(module, func_name, args)
    end
  end

  def default_file_to_json(file) do
    type = get_type(file)
    call_function(type, :file_to_json, [file])
  end

  def base_create_file(user_id, params) do
    type = get_type(params)
    call_function(type, :create_file, [user_id, params])
  end

  def base_get_attributes(params) do
    type = get_type(params)
    call_function(type, :get_attributes, [params])
  end
end
