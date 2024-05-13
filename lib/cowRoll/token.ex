defmodule CowRoll.Token do
  # token for 2 weeks
  @token_age_secs 14 * 86_400
  @alg "HS512"
  @doc """
  Create a JWT token for given data
  """
  def sign(data) do
    claims = Map.put(data, "exp", exp_time())
    signing_key = fetch_signing_key()

    signed = JOSE.JWT.sign(signing_key, %{"alg" => @alg}, claims)
    # Con el elemento 1 obtenemos el token, el elemento 0 es el algoritmo
    JOSE.JWS.compact(signed) |> elem(1)
  end

  @doc """
  Verify given token by:
  - Verify token signature
  - Verify expiration time
  """
  def verify(token) do
    signing_key = fetch_signing_key()

    case JOSE.JWT.verify_strict(signing_key, [@alg], token) do
      {true, jwt, _jws} ->
        exp_time = jwt.fields["exp"]
        current_time = System.os_time(:second)

        if exp_time > current_time do
          {:ok, jwt.fields}
        else
          {:error, :unauthenticated}
        end

      {false, _jwt, _jws} ->
        {:error, :unauthenticated}
    end
  end

  defp fetch_signing_key do
    key = System.get_env("JWT_SECRET_KEY") || Application.get_env(:cowRoll, :jwt_secret_key)

    unless key do
      raise "JWT_SECRET_KEY no está definida en las variables de entorno."
    end

    {:ok, decoded_key} = Base.decode64(key)
    JOSE.JWK.from_oct(decoded_key)
  end

  defp exp_time do
    System.os_time(:second) + @token_age_secs
  end
end
