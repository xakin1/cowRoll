defmodule CowRoll.Schemas.Users.Users do
  import CowRollWeb.ErrorCodes
  import CowRoll.Utils.Functions

  @collection "users"

  def get_user_by_id(user_id) do
    case Mongo.find_one(:mongo, @collection, %{id: user_id}) do
      nil -> user_not_found()
      user -> user
    end
  end

  def get_user_by_username(username) do
    Mongo.find_one(:mongo, @collection, %{username: username})
  end

  def insert_user(user) do
    id = get_unique_id()
    user = Map.put(user, :id, id)

    case Mongo.insert_one(:mongo, @collection, user) do
      {:ok, _result} ->
        {:ok, id}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete_user(user_id) do
    user = %{id: user_id}

    case Mongo.delete_one(:mongo, @collection, user) do
      {:ok, _result} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end
end
