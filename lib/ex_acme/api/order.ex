defmodule ExAcme.Order do
  alias ExAcme.{Challenge, Error}

  import ExAcme.Utils, only: [api: 1, to_struct: 1]

  defstruct location: nil,
            expires: nil,
            not_before: nil,
            not_after: nil,
            identifiers: [],
            authorizations: [],
            finalize: nil,
            certificate: nil,
            status: nil

  @doc "Generate a new order"
  def new_order(client, domains, attrs \\ %{}) do
    order = to_struct(attrs) |> put_identifiers(domains)

    case api(client).new_order(client.api_client, order) do
      {:ok, %{status: 201} = env} -> {:ok, to_struct(env)}
      {_, env} -> {:error, env.body}
    end
  end

  @doc "Finalize the order and generate the certificate after challenge is completed"
  def finalize_order(client, %__MODULE__{} = order, csr) do
    der_csr = ExAcme.Certificate.to_base64_der(csr)

    case api(client).finalize_order(client.api_client, order.finalize, %{"csr" => der_csr}) do
      {:ok, %{status: 403} = env} -> {:error, Error.build_error(env.body)}
    end
  end

  def get_order(client, %__MODULE__{location: order_url}), do: get_order(client, order_url)

  def get_order(client, order_url) do
    case api(client).get_order(client.api_client, order_url) do
      {:ok, %{status: 200} = env} -> {:ok, %{to_struct(env) | location: order_url}}
      {_, env} -> {:error, env.body}
    end
  end

  def get_challenges(client, %__MODULE__{authorizations: authz}) do
    Enum.flat_map(authz, fn url ->
      {:ok, env} = api(client).get_authz(client, url)
      env.body[:challenges]
    end)
    |> Enum.map(fn challenge -> struct!(Challenge, challenge) end)
  end

  def get_challenge(client, order, find_type) do
    get_challenges(client, order) |> Enum.find(fn %{type: type} -> type == find_type end)
  end

  def respond_challenge(client, %Challenge{} = challenge) do
    api(client).respond_order(client, challenge.url)
  end

  def put_identifiers(%__MODULE__{} = order, domains) when is_list(domains) do
    identifiers = domains |> Enum.map(fn domain -> %{type: "dns", value: domain} end)
    %{order | identifiers: identifiers}
  end

  def put_identifiers(order, domains), do: put_identifiers(order, [domains])
end
