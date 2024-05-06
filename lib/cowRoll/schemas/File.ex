defmodule CowRoll.File do
  use Ecto.Schema
  import CowRoll.Utils.Functions
  import CowRoll.Schemas.Helper

  @file_type "File"
  @directory_collection "code"

  def get_attributes(params) do
    %{
      "name" => params["name"],
      "directory_id" => params["directoryId"],
      "cantent" => params["content"]
    }
  end

  def update_directory_id(params, directory_id) do
    Map.merge(params, %{"directory_id" => directory_id})
  end

  def update_or_create_file(user_id, params) do
    query =
      Map.merge(
        %{
          "user_id" => user_id
        },
        params
      )

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        insert_one_file(user_id, params)

      %{"_id" => existing_id} ->
        updates = get_updates(params)

        Mongo.update_one(:mongo, @directory_collection, %{"_id" => existing_id}, updates)
    end
  end

  def update_file(user_id, file_id, attrs) do
    query = %{
      "user_id" => user_id,
      "id" => file_id,
      "type" => @file_type
    }

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        {:error, "File not found"}

      %{"_id" => existing_id} ->
        updates = get_updates(attrs)

        Mongo.update_one(:mongo, @directory_collection, %{"_id" => existing_id}, updates)
        {:ok, "File updated"}
    end
  end

  def delete_files(params) do
    query = %{
      "type" => @file_type
    }

    query = Map.merge(query, params)

    case Mongo.delete_many(:mongo, @directory_collection, query) do
      {:ok, deletes} -> deletes.deleted_count
      _ -> 0
    end
  end

  def delete_file(user_id, file_id) do
    query = %{
      "user_id" => user_id,
      "id" => file_id,
      "type" => @file_type
    }

    deletes = Mongo.delete_one!(:mongo, @directory_collection, query)
    deletes.deleted_count
  end

  def get_file(user_id, file_id) do
    query = %{
      "user_id" => user_id,
      "id" => file_id,
      "type" => @file_type
    }

    file = Mongo.find_one(:mongo, @directory_collection, query)

    if(file != nil) do
      %{
        :id => file["id"],
        :name => file["name"],
        :content => file["content"],
        :directoryId => file["directory_id"]
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

  def insert_one_file(user_id, params \\ %{}) do
    id = get_unique_id()

    if(params["name"] == "" or params["name"] == nil) do
      {:error, "The name of the file can't be empty."}
    else
      if(params["directory_id"] == "" or params["directory_id"] == nil) do
        {:error, "The file needs a parent directory"}
      else
        default_params = %{
          "id" => get_unique_id(),
          "user_id" => user_id,
          "type" => @file_type
        }

        params = Map.merge(default_params, params)

        Mongo.insert_one(:mongo, @directory_collection, params)

        {:ok, id}
      end
    end
  end
end
