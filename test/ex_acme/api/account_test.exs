defmodule ExAcme.AccountTest do
  use ExAcme.DataCase, async: true
  alias ExAcme.{Account, AccountKey}

  describe "new_account/3" do
    setup do
      {:ok, key} = AccountKey.create_key()

      [account_key: key]
    end

    test "creates new account", %{account_key: account_key} do
      Account.new_account(account_key, %{}, adapter: __MODULE__.MockClient) |> dbg()
    end
  end

  defmodule MockClient do
    def client(account_key), do: account_key

    def new_account(account_key, payload) do
      {:ok, fixture!(:new_account)}
    end
  end
end
