defmodule CowRoll.File do
  use Ecto.Schema
  import CowRoll.Utils.Functions
  import CowRoll.Schemas.Helper

  @file_type "File"
  @directory_collection "code"

  def get_attributes(params) do
    %{
      name: params["name"],
      directory_id: params["directoryId"],
      content: params["content"]
    }
  end

  def update_or_create_file(name, user_id, content, directory_id) do
    query = %{
      user_id: user_id,
      name: name,
      directory_id: directory_id
    }

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        insert_one(user_id, name, content, directory_id)

      %{"_id" => existing_id} ->
        Mongo.update_one(:mongo, @directory_collection, %{_id: existing_id}, %{
          "$set" => %{content: content}
        })
    end
  end

  def update_file(user_id, file_id, attrs) do
    query = %{
      user_id: user_id,
      id: file_id,
      type: @file_type
    }

    case Mongo.find_one(:mongo, @directory_collection, query) do
      nil ->
        {:error, "File not found"}

      %{"_id" => existing_id} ->
        updates = get_updates(attrs)

        Mongo.update_one(:mongo, @directory_collection, %{_id: existing_id}, updates)
        {:ok, "File updated"}
    end
  end

  def delete_file(user_id, file_id) do
    query = %{
      user_id: user_id,
      id: file_id,
      type: @file_type
    }

    deletes = Mongo.delete_one!(:mongo, @directory_collection, query)
    deletes.deleted_count
  end

  def get_file(user_id, file_id) do
    query = %{
      user_id: user_id,
      id: file_id,
      type: @file_type
    }

    file = Mongo.find_one(:mongo, @directory_collection, query)

    if(file != nil) do
      %{
        fileId: file["id"],
        name: file["name"],
        content: file["content"],
        directoryId: file["directory_id"]
      }
    else
      %{}
    end
  end

  def get_files(params) do
    query = %{
      type: @file_type
    }

    query = Map.merge(query, params)
    Mongo.find(:mongo, @directory_collection, query) |> Enum.to_list()
  end

  def insert_one(user_id, name, content, directory_id, type \\ @file_type) do
    Mongo.insert_one(:mongo, @directory_collection, %{
      id: get_unique_id(),
      user_id: user_id,
      name: name,
      content: content,
      type: type,
      directory_id: directory_id
    })
  end
end
