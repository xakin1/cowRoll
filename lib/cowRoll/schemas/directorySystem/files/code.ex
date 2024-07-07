defmodule CowRoll.Code do
  @moduledoc """
  Módulo base para manejar ficheros de código en MongoDB.
  """
  use CowRoll.File
  import CowRoll.Utils.Functions
  import CowRoll.Schemas.Helper
  import CowRollWeb.ErrorCodes

  @file_type "Code"
  @directory_id "directory_id"
  @name "name"
  @content_schema "content_schema"
  @backpack_schema "backpack_schema"
  @id "id"
  @user_id "user_id"
  @type_key "type"
  @file_system "file_system"

  def get_attributes(params) do
    base_attributes = get_base_attributes(params)

    Map.merge(base_attributes, %{
      @content_schema => params["contentSchema"],
      @backpack_schema => params["backpackSchema"]
    })
  end

  def get_content_schema(params) do
    params[@content_schema]
  end

  def get_backpack_schema(params) do
    params[@backpack_schema]
  end

  def create_file(user_id, params) do
    params = %{
      @user_id => user_id,
      @directory_id => get_directory_id(params),
      @name => get_name(params),
      @type_key => @file_type
    }

    insert_file(user_id, params)
  end

  def get_files_with_code(params) do
    query = %{
      @type_key => @file_type
    }

    query = Map.merge(query, params)
    get_files(query)
  end

  def update_file(user_id, params) do
    update_file(user_id, params, @file_type)
  end

  def file_to_json(file) do
    if(file != nil) do
      %{
        id: get_id(file),
        name: get_name(file),
        type: get_type(file),
        content: get_content(file),
        contentSchema: get_content_schema(file),
        backpackSchema: get_backpack_schema(file),
        directoryId: get_directory_id(file)
      }
    else
      %{}
    end
  end

  def insert_one_file(user_id, params \\ %{}) do
    id = get_unique_id()
    params = clean_params(params)
    name = get_name(params)
    directory_id = get_directory_id(params)

    if(name == "" or name == nil) do
      {:error, empty_file_name()}
    else
      if(directory_id == "" or directory_id == nil) do
        {:error, parent_not_found()}
      else
        default_params = %{
          @user_id => user_id,
          @type_key => @file_type
        }

        params = Map.merge(default_params, params)
        params = Map.put(params, @id, id)

        case Mongo.insert_one(:mongo, @file_system, params) do
          {:ok, _result} ->
            {:ok, id}

          {:error, reason} ->
            {:error, reason}
        end
      end
    end
  end
end
