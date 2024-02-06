defmodule ExAcme.Revoke do
  alias ExAcme.Error

  import ExAcme.Utils, only: [api: 1]

  def revoke_certificate(client, certificate, reason) do
    der_cert = ExAcme.Certificate.to_base64_der(certificate)

    case api(client).revoke_certificate(client.api_client, %{certificate: der_cert, reason: reason}) do
      {:ok, %{status: 200}} -> :ok
      {:ok, %{status: 400} = env} -> {:error, Error.build_error(env.body)}
    end
  end
end
