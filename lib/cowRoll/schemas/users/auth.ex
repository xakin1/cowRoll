defmodule CowRoll.Schemas.Users.Auth do
  import CowRollWeb.ErrorCodes
  import CowRoll.Schemas.Users.Users

  @collection "users"

  def get_attributes(params) do
    %{
      username: params["username"],
      password: params["password"]
    }
  end

  def get_username(params) do
    params[:username]
  end

  def get_password(params) do
    params[:password]
  end

  def register_user(params) do
    password = params |> get_password()
    username = get_username(params)

    case validate_params(params) do
      {:ok, []} ->
        case get_user_by_username(username) do
          nil ->
            hashed_password = hash_password(password)

            user = %{username: username, password: hashed_password}

            with {:ok, id} <- insert_user(user) do
              {:ok, %{id: id, token: generate_jwt_token(id)}}
            end

          _ ->
            {:error, user_name_already_exits()}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def unregister_user(user_id) do
    case delete_user(user_id) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_user_id(params) do
    case Mongo.find(:mongo, @collection, %{username: get_username(params)}, limit: 1)
         |> Enum.to_list() do
      [%{"password" => _db_password, "id" => user_id}] ->
        {:ok, user_id}

      [] ->
        {:error, user_not_found()}
    end
  end

  def login_user(params) do
    case Mongo.find(:mongo, @collection, %{username: get_username(params)}, limit: 1)
         |> Enum.to_list() do
      [%{"password" => db_password, "id" => user_id}] ->
        if params |> get_password() |> verify_password(db_password) do
          token = generate_jwt_token(user_id)
          {:ok, token}
        else
          {:error, invalid_credentials()}
        end

      [] ->
        {:error, user_not_found()}
    end
  end

  defp generate_jwt_token(user_id) do
    data = %{"user_id" => user_id}
    CowRoll.Token.sign(data)
  end

  defp validate_params(params) do
    Enum.reduce(params, {:ok, []}, fn
      {key, value}, {:ok, _acc} ->
        func_name = :"validate_#{Atom.to_string(key)}"

        if function_exported?(__MODULE__, func_name, 1) do
          case apply(__MODULE__, func_name, [value]) do
            :ok -> {:ok, []}
            {:error, reason} -> {:error, reason}
          end
        else
          {:ok, []}
        end

      {_, _}, {:error, _} = error ->
        error
    end)
  end

  def validate_password(password) do
    cond do
      password == "" or password == nil ->
        {:error, empty_password()}

      String.length(password) < 8 ->
        {:error, minimun_length()}

      not Regex.match?(~r/[0-9]/, password) ->
        {:error, digits()}

      not Regex.match?(~r/[A-Z]/, password) ->
        {:error, uper_case()}

      not Regex.match?(~r/[a-z]/, password) ->
        {:error, lower_case()}

      not Regex.match?(~r/[^a-zA-Z0-9]/, password) ->
        {:error, special_characteres()}

      true ->
        :ok
    end
  end

  def validate_username(username) do
    cond do
      username == nil or username == "" ->
        {:error, empty_user_name()}

      true ->
        :ok
    end
  end

  defp hash_password(password) do
    case Mix.env() do
      :dev -> password
      :test -> password
      _ -> Argon2.hash_pwd_salt(password)
    end
  end

  defp verify_password(password, hashed_password) do
    case Mix.env() do
      :dev -> password == hashed_password
      :test -> password == hashed_password
      _ -> Argon2.verify_pass(password, hashed_password)
    end
  end
end
