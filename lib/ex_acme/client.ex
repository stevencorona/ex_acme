defmodule ExAcme.Client do
  defstruct [:account_key, :api_client]

  alias ExAcme.Api

  def client(account_key) do
    %__MODULE__{api_client: Api.client(account_key), account_key: account_key}
  end
end
