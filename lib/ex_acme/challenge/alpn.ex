defmodule ExAcme.Challenge.Alpn do
  require Logger
  require Record

  Record.defrecordp(
    :otp_tbs_certificate,
    :OTPTBSCertificate,
    Record.extract(:OTPTBSCertificate, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  Record.defrecordp(
    :signature_algorithm,
    :SignatureAlgorithm,
    Record.extract(:SignatureAlgorithm, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  Record.defrecordp(
    :validity,
    :Validity,
    Record.extract(:Validity, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  Record.defrecordp(
    :public_key_algorithm,
    :PublicKeyAlgorithm,
    Record.extract(:PublicKeyAlgorithm, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  Record.defrecordp(
    :extension,
    :Extension,
    Record.extract(:Extension, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  Record.defrecordp(
    :attr,
    :AttributeTypeAndValue,
    Record.extract(:AttributeTypeAndValue, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  Record.defrecordp(
    :otp_subject_public_key_info,
    :OTPSubjectPublicKeyInfo,
    Record.extract(:OTPSubjectPublicKeyInfo, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  Record.defrecordp(
    :rsa_private_key,
    :RSAPrivateKey,
    Record.extract(:RSAPrivateKey, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  Record.defrecordp(
    :rsa_public_key,
    :RSAPublicKey,
    Record.extract(:RSAPublicKey, from_lib: "public_key/include/OTP-PUB-KEY.hrl")
  )

  def test() do
    private_key = :public_key.generate_key({:rsa, 4096, 65537})

    acme_certificate(private_key) |> IO.inspect() |> :public_key.pkix_sign(private_key)
  end

  defp extract_public_key(rsa_private_key(modulus: m, publicExponent: e)) do
    rsa_public_key(modulus: m, publicExponent: e)
  end

  @rsaEncryption {1, 2, 840, 113_549, 1, 1, 1}
  @sha256WithRSAEncryption {1, 2, 840, 113_549, 1, 1, 11}

  def acme_certificate(private_key) do
    public_key = extract_public_key(private_key)
    common_name = ""
    hostnames = ["test.com"]

    <<serial::unsigned-64>> = :crypto.strong_rand_bytes(8)

    # Dates must be in 'YYMMDD' format
    {{year, month, day}, _} =
      :erlang.timestamp()
      |> :calendar.now_to_datetime()

    yy = year |> Integer.to_string() |> String.slice(2, 2)
    mm = month |> Integer.to_string() |> String.pad_leading(2, "0")
    dd = day |> Integer.to_string() |> String.pad_leading(2, "0")

    not_before = yy <> mm <> dd

    yy2 = (year + 1) |> Integer.to_string() |> String.slice(2, 2)

    not_after = yy2 <> mm <> dd

    otp_tbs_certificate(
      version: :v3,
      serialNumber: serial,
      signature: signature_algorithm(algorithm: @sha256WithRSAEncryption, parameters: :NULL),
      issuer: rdn(common_name),
      validity:
        validity(
          notBefore: {:utcTime, '#{not_before}000000Z'},
          notAfter: {:utcTime, '#{not_after}000000Z'}
        ),
      subject: rdn(common_name),
      subjectPublicKeyInfo:
        otp_subject_public_key_info(
          algorithm: public_key_algorithm(algorithm: @rsaEncryption, parameters: :NULL),
          subjectPublicKey: public_key
        ),
      extensions: extensions(public_key, hostnames)
    )
  end

  @organizationName {2, 5, 4, 10}
  @commonName {2, 5, 4, 3}

  defp rdn(common_name) do
    {:rdnSequence,
     [
       [attr(type: @organizationName, value: {:utf8String, "Phoenix Framework"})],
       [attr(type: @commonName, value: {:utf8String, common_name})]
     ]}
  end

  @subjectAlternativeName {2, 5, 29, 17}
  @acmeId {1, 3, 6, 1, 5, 5, 7, 1, 31}

  defp extensions(public_key, hostnames) do
    [
      # extension(
      #   extnID: @basicConstraints,
      #   critical: true,
      #   extnValue: basic_constraints(cA: false)
      # ),
      # extension(
      #   extnID: @keyUsage,
      #   critical: true,
      #   extnValue: [:digitalSignature, :keyEncipherment]
      # ),
      # extension(
      #   extnID: @extendedKeyUsage,
      #   critical: false,
      #   extnValue: [@serverAuth, @clientAuth]
      # ),
      extension(
        extnID: @acmeId,
        critical: true,
        extnValue: String.to_charlist("sha256")
      ),
      extension(
        extnID: @subjectAlternativeName,
        critical: false,
        extnValue: Enum.map(hostnames, &{:dNSName, String.to_charlist(&1)})
      )
    ]
  end

  def listen(account_key) do
    private_key = :public_key.generate_key({:rsa, 4096, 65537})

    k = :public_key.der_encode(:RSAPrivateKey, private_key)

    cert = acme_certificate(private_key) |> :public_key.pkix_sign(private_key)

    IO.inspect(k)

    # c = :public_key.pkix_encode(:OTPCertificate, cert, :otp)
    # IO.inspect(c)

    # {:ok, socket} = :gen_tcp.listen(8080, [:binary, packet: :http, active: false, reuseaddr: true])
    {:ok, socket} = :ssl.listen(8081, [:binary, key: {:RSAPrivateKey, k}, cert: cert, alpn_preferred_protocols: ["acme-tls/1"]])

    Logger.info("Accepting connections on port")

    {:ok, client} = :ssl.transport_accept(socket)
    {:ok, client} = :ssl.handshake(client)

    :ssl.negotiated_protocol(client) |> IO.inspect()

    # accept(socket, account_key)
  end
end
