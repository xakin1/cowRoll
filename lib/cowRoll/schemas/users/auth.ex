defmodule CowRoll.Schemas.Users.Auth do
  import Argon2
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
            # Posiblemente esto venga haseado de la web pero mientras tanto lo hasheamos local
            hashed_password = password |> hash_pwd_salt()

            user = %{username: username, password: hashed_password}
            insert_user(user)

          _ ->
            {:error, user_name_already_exits()}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def login_user(params) do
    case Mongo.find(:mongo, @collection, %{username: get_username(params)}, limit: 1)
         |> Enum.to_list() do
      [%{"password" => db_password, "id" => user_id}] ->
        if params |> get_password() |> Argon2.verify_pass(db_password) do
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

  # Valida todos los parametros si es que tienen una función de validación
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
          # Si no existe la función de validación, pasa sin acción
          {:ok, []}
        end

      {_, _}, {:error, _} = error ->
        # Propaga el primer error encontrado
        error
    end)
  end

  # Las funciones de validacion tienen que ser publicas para que validate_params las "vea"
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
end
