# ExAcme

A full-featured ACME v2 client library for Elixir.

Lightweight, functional ACME client library for Elixir for provisioning SSL certificates. This library has been tested against LetsEncrypt but is compatible with any ACME v2 server.

The goal of the project is to offer a flexible and standalone ACME client library that has no framework or web server ties (i.e, no dependency on phoenix or cowboy), no supervision tree, and gives you full control over private key + certificate generation/storage/renewal. 

By default, private keys and certificates are generated using erlang standard library (no requirement on openssl cli or shelling) and are fully managed in memory without any compile-time dependencies or configuration. This allows library users full flexibility in a multi-tenant or dynamic hostname environment, where many certificates are generated on-the-fly and stored in a centralized database.

## Features
- ACME v2 RFC 8555
- Register with CA
- Lightweight and functional (no supervision tree)

### TODO
- Robust implementation of all ACME challenges (TODO)
  - HTTP (http-01)
  - DNS (dns-01)
  - TLS (tls-alpn-01)
- (Optional) Plug for automatic certifiate provisioning/renewal
- (Optional) Rate limiting quotas

## Basic Usage

### Register a new account
Before you can generate a certificate, you need to create an account

```
# Generate an ecdsa private key for your account
iex> {:ok, account_key} = ExAcme.AccountKey.create_key()

# Create a new ACME account with your provider
iex> {:ok, key_id, _account} = ExAcme.Account.new_account(account_key)

# Update your AccountKey with the key_id from the ACME Server
iex> account_key = ExAcme.AccountKey.put_key_id(account_key, key_id)

# Export AccountKey as a map and store it in a database or other secure store
iex> ExAcme.AccountKey.to_map(account_key)

# Or save it to the filesystem
iex> ExAcme.AccountKey.to_file(account_key, "./acme_key.json")
```

### Generate a certificate
Generating a certificate involves creating an order, completing a challenge, generating a CSR, and finalizing the order.
```
# Load the key from the filesystem
iex> {:ok, account_key} = ExAcme.AccountKey.from_file("./acme_key.json")

# Create an authenticated ACME client
iex> client = ExAcme.Client.build_client(account_key)

# Create a new order
iex> {:ok, order} = ExAcme.Order.new_order(client, ["www.mydomain.com"])

# Get the HTTP-01 challenge for the order
iex> challenge = ExAcme.Order.get_challenge(client, order, "http-01")

# Complete the challenge using another mechanism or, optionally, use the built-in, zero-dependency http server
# The listener will close once the verification is attempted
iex> task = Task.async(fn ->ExAcme.Challenge.HTTP.listen(account_key, challenge) end)

# Notify ACME server that the challenge may be attmepted
iex> ExAcme.Order.respond_challenge(client, challenge)

# Wait until the challenge is checked by ACME server
iex> Task.await(task)

# Check if the challenge is valid
iex> %{status: "valid"} = ExAcme.Order.get_challenge(client, order, "http-01")

# Create a new keypair for the cert & generate a CSR (or provide your own in PEM format)
# Don't lose the private key, you'll need it for the tls server
iex> private_key = ExAcme.Certificate.new_private_key()
iex> csr = ExAcme.Certificate.new_csr(private_key, "www.mydomain.com")

# Submit the CSR and finalize the order w/ the ACME Server
iex> {:ok, order} = ExAcme.Order.finalize_order(client, order, csr)

# Download the signed certificate
iex> {:ok, certificate} = ExAcme.Order.get_certificate(client, order)
```


## ACME Reference
While I was building this, I had trouble finding a clear + succinct explination of the how the ACME protocol works online without having to reference RFC8555 directly. The RFC is good, but here's a 10,000 foot view:

### Registering a new account
1. Client generates an new "account" private keypair (either RSA or ECDSA)
2. Client makes a request to `/acme/new-acct` w/ body signed using this private key
3. Server creates a new account and associates it with your account public key

### Getting a certificate
1. Client makes a request to `/acme/new-order` w/ the hostname it wants a certificate for
2. Server responds with a list of authorization urls.
3. Client makes a request to authorization urls (something like `/acme/authz-v3/12345678`)
4. Server responds with a list of possible challenges (http-01, dns-01, alpn-tls-01)
5. Client completes a challenge (described below)
6. Client makes a request to the challenge url `/acme/chall-v3/12345678/ceZySw` w/ an EMPTY JSON body (i.e `{}`)
7. Server attempts to validate challenge
8. Client polls challenge or order url and waits for challenge to succeed
9. Client generates CSR. CSR must be in der format + base64url encoded (note- not the same as base64 encoding)
10. Client calls finalize url `/acme/finalize/12345678/abc123` with CSR
11. Server generates certificate
12. Client can retrieve certificate by polling order url and making a request to the certificate url

### Notes / Oddities / Frustrations
1. Every request is a POST. If you want to read a resource, you make an empty body POST request ("POST-as-GET")
2. Every request requires a unique nonce. You can generate one using the `/acme/new-nonce` endpoint
3. Every request body is sent as a JWS, which signs + base64 encodes the JSON body
4. No IDs in the payloads, instead there are reference urls in the respoonse location header
5. Seemingly no way to retrieve a list of your orders, so if you lose they url, they're gone
6. Unless you make an order for the exact same domain and then it magically just gives you back the same one?
7. There's a strict rate limit but no way to tell what your current quota is aside from tracking it yourself

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_acme` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_acme, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_acme>.
