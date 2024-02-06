defmodule ExAcme.Api do
  def default_middleware(account_key) do
    [
      {Tesla.Middleware.BaseUrl, "https://acme-staging-v02.api.letsencrypt.org"},
      {Tesla.Middleware.Headers, [{"content-type", "application/jose+json"}]},
      {ExAcme.Tesla.JWSMiddleware, nonce_func: &new_nonce/1, jwk: account_key.private_key, kid: account_key.key_id},
      {Tesla.Middleware.JSON, decode_content_types: ["application/problem+json"], engine_opts: [keys: &camelize_keys/1]}
    ]
  end

  def client(account_key) do
    default_middleware(account_key) |> Tesla.client()
  end

  def new_nonce(client) do
    {:ok, env} = Tesla.head(client, "/acme/new-nonce")
    Tesla.get_header(env, "replay-nonce")
  end

  def new_account(account_key, payload) do
    client(account_key) |> Tesla.post("/acme/new-acct", {:jws, payload})
  end

  def update_account(client, account_url, payload) do
    Tesla.post(client, account_url, {:jws, payload})
  end

  def get_account(client, account_url) do
    Tesla.post(client, account_url, {:jws, :post_as_get})
  end

  def new_order(client, payload) do
    Tesla.post(client, "/acme/new-order", {:jws, payload})
  end

  def get_authz(client, authz_url) do
    Tesla.post(client.api_client, authz_url, {:jws, :post_as_get})
  end

  def get_order(client, order_url) do
    Tesla.post(client, order_url, {:jws, :post_as_get})
  end

  def finalize_order(client, finalize_url, payload) do
    Tesla.post(client, finalize_url, {:jws, payload})
  end

  def respond_order(client, challenge_url) do
    Tesla.post(client, challenge_url, {:jws, %{}})
  end

  defp camelize_keys(key), do: key |> Macro.underscore() |> String.to_existing_atom()
end
