defmodule ExAcme.AccountKeyTest do
  use ExUnit.Case, async: true
  alias ExAcme.AccountKey

  describe "to_map/1" do
    test "success" do
      {:ok, key} = AccountKey.create_key()
      %{"key_id" => nil, "private_key" => pk} = AccountKey.to_map(key)

      assert %{"kty" => "EC", "x" => _} = pk
    end
  end

  describe "from_map/1" do
    test "success" do
      {:ok, key} = AccountKey.create_key()
      %{"key_id" => nil, "private_key" => pk} = AccountKey.to_map(key)
      key = AccountKey.from_map(%{"key_id" => nil, "private_key" => pk})

      assert key.key_id == nil
      assert %JOSE.JWK{} = key.private_key
    end
  end
end
