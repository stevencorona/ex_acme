defmodule ExAcme.Tesla.JWSMiddlewareTest do
  use ExUnit.Case
  doctest ExAcme.Tesla.JWSMiddleware
  alias ExAcme.Tesla.JWSMiddleware

  describe "build_body/3" do
    @describetag key_id: nil
    setup context do
      {:ok, key} = ExAcme.AccountKey.create_key()
      key = ExAcme.AccountKey.put_key_id(key, context.key_id)

      {:ok, key: key}
    end

    test "successfully builds and signs jws", %{key: key} do
      url = "https://example.org/new-acct"
      env = %{url: url, client: nil}

      {:ok, signed} =
        JWSMiddleware.build_body(env, %{"foo" => "bar"}, %{
          jwk: key.private_key,
          nonce_func: fn _ -> "nonce" end,
          signing_algo: "ES384"
        })

      assert {true, "{\"foo\":\"bar\"}", jws} =
               JOSE.JWS.verify_strict(key.private_key, ["ES384"], signed)

      assert jws.fields["url"] == url

      {_, jwk_map} = JOSE.JWK.to_map(key.private_key)

      assert jws.fields["jwk"]["x"] == jwk_map["x"]
      assert jws.fields["jwk"]["y"] == jwk_map["y"]
    end

    @tag key_id: "https://example.org/acme/acct/9999"
    test "prefers kid when present", %{key: key} do
      url = "https://example.org/new-acct"
      env = %{url: url, client: nil}

      {:ok, signed} =
        JWSMiddleware.build_body(env, %{"foo" => "bar"}, %{
          jwk: key.private_key,
          kid: key.key_id,
          nonce_func: fn _ -> "nonce" end,
          signing_algo: "ES384"
        })

      assert {true, "{\"foo\":\"bar\"}", jws} =
               JOSE.JWS.verify_strict(key.private_key, ["ES384"], signed)

      assert jws.fields["url"] == url
      refute jws.fields["jwk"]
      assert jws.fields["kid"] == key.key_id
    end
  end
end
