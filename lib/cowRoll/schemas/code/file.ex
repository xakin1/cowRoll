defmodule CowRoll.File do
  import CowRoll.Utils.Functions
  import CowRoll.Schemas.Helper
  import CowRollWeb.ErrorCodes
  import CowRollWeb.SuccesCodes

  @file_type "File"
  @directory_collection "code"
  @directory_id "directory_id"
  @name "name"
  @content "content"
  @content_schema "content_schema"
  @id "id"
  @user_id "user_id"
  @type_key "type"
  @mongo_id "_id"

  def get_attributes(params) do
    %{
      @name => params["name"],
      @directory_id => params["directoryId"],
      @content => params["content"],
      @content_schema => params["contentSchema"],
      @id => params["id"]
    }
  end

  @spec get_content(nil | maybe_improper_list() | map()) :: any()
  def get_content(params) do
    params[@content]
  end

  def get_content_schema(params) do
    params[@content_schema]
  end

  def get_id(params) do
    params[@id]
  end

  def get_directory_id(params) do
    params[@directory_id]
  end

  def set_directory_id(params, directory_id) do
    Map.merge(params, %{@directory_id => directory_id})
  end

  def get_name(params) do
    params[@name]
  end

  def get_type(params) do
    params[@type_key]
  end

  def update_directory_id(params, directory_id) do
    set_directory_id(params, directory_id)
  end

  def update_or_create_file(user_id, params) do
    query =
      %{
        @user_id => user_id,
        @id => get_id(params)
      }

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        insert_one_file(user_id, params)

      %{@mongo_id => existing_id} ->
        updates = get_updates(params)

        Mongo.update_one(:mongo, @directory_collection, %{@mongo_id => existing_id}, updates)
    end
  end

  def create_file(user_id, params) do
    query = %{
      @user_id => user_id,
      @directory_id => get_directory_id(params),
      @name => get_name(params),
      @type_key => @file_type
    }

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        insert_one_file(user_id, query)

      _ ->
        {:error, file_name_already_exits()}
    end
  end

  def update_file(user_id, params) do
    query = %{
      @user_id => user_id,
      @id => get_id(params),
      @type_key => @file_type
    }

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        {:error, file_not_found()}

      %{@mongo_id => existing_id} ->
        updates = get_updates(params)

        Mongo.update_one(:mongo, @directory_collection, %{@mongo_id => existing_id}, updates)
        {:ok, file_updated()}
    end
  end

  def delete_files(params) do
    query = %{
      @type_key => @file_type
    }

    query = Map.merge(query, params)

    case Mongo.delete_many(:mongo, @directory_collection, query) do
      {:ok, deletes} -> deletes.deleted_count
      _ -> 0
    end
  end

  def delete_file(user_id, file_id) do
    query = %{
      @user_id => user_id,
      @id => file_id,
      @type_key => @file_type
    }

    deletes = Mongo.delete_one!(:mongo, @directory_collection, query)
    deletes.deleted_count
  end

  def get_file(user_id, file_id) do
    query = %{
      @user_id => user_id,
      @id => file_id,
      @type_key => @file_type
    }

    file = Mongo.find_one(:mongo, @directory_collection, query)

    if(file != nil) do
      %{
        :id => file[@id],
        :name => file[@name],
        :content => file[@content],
        :contentSchema => file[@content_schema],
        :directoryId => file[@directory_id]
      }
    else
      %{}
    end
  end

  def get_files(params) do
    query = %{
      "type" => @file_type
    }

    query = Map.merge(query, params)
    Mongo.find(:mongo, @directory_collection, query) |> Enum.to_list()
  end

  def find_file(user_id, params) do
    case Mongo.find_one(:mongo, @directory_collection, %{
           @id => get_id(params),
           # No debería hacer falte pero por si acaso
           @user_id => user_id
         }) do
      nil ->
        {:error, file_not_found()}

      file ->
        {:ok, file[@id]}
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

        case Mongo.insert_one(:mongo, @directory_collection, params) do
          {:ok, _result} ->
            {:ok, id}

          {:error, reason} ->
            {:error, reason}
        end
      end
    end
  end
end
