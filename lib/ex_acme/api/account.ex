defmodule ExAcme.Account do
  alias ExAcme.{AccountKey, Error}

  import ExAcme.Utils, only: [api: 1]

  defstruct [
    :location,
    :initial_ip,
    :created_at,
    :status,
    key: %{crv: nil, initial_ip: nil, created_at: nil},
    contact: [],
    terms_of_service_agreed: true,
    only_return_existing: true
  ]

  def new_account(%AccountKey{} = account_key, attrs \\ %{}, adapter \\ nil) do
    account = struct!(__MODULE__, attrs)

    case api(adapter).new_account(account_key, account) do
      {:ok, %{status: 200} = env} -> {:ok, to_struct(env)}
      {:ok, env} -> {:error, Error.build_error(env.body)}
    end
  end

  def get_account(client, %__MODULE__{location: account_url}), do: get_account(client, account_url)

  def get_account(client, account_url) do
    case api(client).get_account(client.api_client, account_url) do
      {:ok, %{status: 200} = env} -> {:ok, to_struct(env, location: account_url)}
      {:ok, env} -> {:error, Error.build_error(env.body)}
    end
  end

  def update_account(client, %__MODULE__{} = account, attrs \\ %{}) do
    case api(client).update_account(client.api_client, account.location, attrs) do
      {:ok, %{status: 200} = env} -> {:ok, to_struct(env, location: account.location)}
      {:ok, env} -> {:error, Error.build_error(env.body)}
    end
  end

  def deactive_account(client, account), do: update_account(client, account, %{status: "deactivated"})

  def to_struct(%Tesla.Env{body: body} = env), do: Map.put_new(body, :location, Tesla.get_header(env, "location")) |> to_struct()
  def to_struct(attrs), do: struct!(__MODULE__, attrs)
  def to_struct(attrs, extra), do: to_struct(attrs) |> Map.merge(Enum.into(extra, %{}))
end
