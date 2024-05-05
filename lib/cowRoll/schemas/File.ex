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
      userId: user_id,
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
      userId: user_id,
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

  def insert_one(user_id, name, content, directory_id, type \\ @file_type) do
    Mongo.insert_one(:mongo, @directory_collection, %{
      id: get_unique_id(),
      userId: user_id,
      name: name,
      content: content,
      type: type,
      directory_id: directory_id
    })
  end
end
