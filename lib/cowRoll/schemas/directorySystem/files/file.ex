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
      def update_file(user_id, params, type), do: CowRoll.File.update_file(user_id, params, type)

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
      @id => params["id"]
    }
  end

  def get_id(params) do
    params[@id]
  end

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

  def update_file(user_id, params, type) do
    query = %{
      @user_id => user_id,
      @id => get_id(params),
      @type_key => type
    }

    case Mongo.find_one(:mongo, @file_system, query) do
      nil ->
        {:error, file_not_found()}

      %{@mongo_id => existing_id} ->
        updates = get_updates(params)

        Mongo.update_one(:mongo, @file_system, %{@mongo_id => existing_id}, updates)
        {:ok, file_updated()}
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

  def default_file_to_json(file) do
    type = get_type(file)

    case type do
      @code_type -> CowRoll.Code.file_to_json(file)
      @sheet_type -> CowRoll.Sheet.file_to_json(file)
      _ -> %{}
    end
  end
end
