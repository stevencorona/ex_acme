defmodule ExAcme.Certificate do
  @moduledoc """
  Wrappers for generating keys and certificates - used both for certificate request process + creating self-signed
  certificates for ALPN challenge. Originally called erlang :public_key directly, but was painful to work with, so
  now uses the X509 library which makes :public_key much nicer to work with :-)

  Credit to phx.gen.cert task, which serves as a clean example on how to use :public_key directly
  https://github.com/phoenixframework/phoenix/blob/v1.7.2/lib/mix/tasks/phx.gen.cert
  """

  def new_private_key() do
    X509.PrivateKey.new_rsa(2048)
  end

  def new_csr(private_key, hostname) do
    csr =
      X509.CSR.new(private_key, "/C=US/ST=NT/L=Springfield/O=ACME Inc",
        extension_request: [
          X509.Certificate.Extension.subject_alt_name([hostname])
        ]
      )

    IO.inspect(X509.CSR.valid?(csr))
    IO.inspect(X509.CSR.to_pem(csr))

    csr
  end

  def to_base64_der(cert) do
    to_der!(cert) |> Base.url_encode64()
  end

  def to_der!("-----BEGIN CERTIFICATE REQUEST-----" <> _ = pem) do
    X509.Certificate.from_pem(pem) |> X509.CSR.to_der()
  end

  def to_der!({:CertificationRequest, _, _, _} = cert) do
    X509.CSR.to_der(cert)
  end

  def to_der!(cert) when is_binary(cert), do: cert
end
