defmodule ExAcme.Tesla.JWSMiddleware do
  @moduledoc """
  Tesla Middleware for converting request body into signed JWS payloads
  """
  @behaviour Tesla.Middleware

  defstruct [:jwk, :kid, :nonce_func, signing_algo: "ES384"]

  @impl true
  def call(%Tesla.Env{body: {:jws, body}} = env, next, opts) do
    opts = struct!(__MODULE__, opts)

    {:ok, body} = build_body(env, body, opts)
    env = %{env | body: body}

    Tesla.run(env, next)
  end

  def call(env, next, _opts), do: Tesla.run(env, next)

  def build_body(env, body, opts) do
    jws =
      %{
        "alg" => opts.signing_algo,
        "nonce" => new_nonce(env.__client__, opts),
        "url" => env.url
      }
      |> put_key(opts)

    {_, body} = JOSE.JWS.sign(opts.jwk, encode(body), jws)

    {:ok, body}
  end

  defp encode(:post_as_get), do: ""
  defp encode(body), do: Jason.encode!(body)

  defp new_nonce(client, %{nonce_func: f}) when is_function(f), do: f.(client)
  defp new_nonce(_client, _opts), do: ""

  defp put_key(jws, %{kid: kid}) when not is_nil(kid), do: Map.put(jws, "kid", kid)
  defp put_key(jws, %{jwk: jwk}), do: Map.put(jws, "jwk", to_public(jwk))

  defp to_public(jwk) do
    {_, public} = JOSE.JWK.to_public_map(jwk)

    public
  end
end
