defmodule ExAcme.AccountKey do
  defstruct [:key_id, :private_key]

  # The account key algorithms supported by LetsEncrypt
  @valid_algo_types [{:ec, "P-256"}, {:ec, "P-384"}, {:rsa, 2048}, {:rsa, 3072}, {:rsa, 4096}]

  # Use ECDSA-384 as the default algorithm (TODO: Allow this to be configured in config)
  @default_algo {:ec, "P-384"}

  @doc "Create a new account key"
  def create_key(alg \\ @default_algo) when alg in @valid_algo_types do
    key = %__MODULE__{private_key: generate_private_key(alg)}
    {:ok, key}
  end

  @doc "Generates ACME key authorization from challenge token, used during verification"
  def key_authorization(%__MODULE__{} = key, challenge_token) do
    challenge_token <> "." <> thumbprint(key.private_key)
  end

  @doc "Puts the key id into the AccountKey, used after the key is registered w/ server"
  def put_key_id(%__MODULE__{} = key, id) do
    %{key | key_id: id}
  end

  @doc "Turn AccountKey into a map, including the inner private key struct"
  def to_map(key) do
    {_, jwk_map} = JOSE.JWK.to_map(key.private_key)
    %{"key_id" => key.key_id, "private_key" => jwk_map}
  end

  @doc "Turn map into an AccountKey, including loading the inner private key"
  def from_map(%{"key_id" => key_id, "private_key" => private_key}) do
    %__MODULE__{key_id: key_id, private_key: JOSE.JWK.from_map(private_key)}
  end

  @doc "Store AccountKey onto the filesystem"
  def to_file(%__MODULE__{} = key, path) do
    File.write(path, to_map(key) |> Jason.encode!())
  end

  @doc "Load AccountKey from the filesystem"
  def from_file(path) do
    {:ok, File.read!(path) |> Jason.decode!() |> from_map()}
  end

  defp generate_private_key(alg), do: JOSE.JWK.generate_key(alg)
  defp thumbprint(private_key), do: JOSE.JWK.thumbprint(:sha256, private_key)
end
