defmodule ExAcme.Challenge.Http do
  require Logger

  @path_prefix "/.well-known/acme-challenge/"

  def handle_challenge(%{method: "GET", host: _host, request_path: @path_prefix <> token}, account_key) do
    {:ok, ExAcme.AccountKey.key_authorization(account_key, token)}
  end

  def handle_challenge(_, _) do
    {:error, :bad_request}
  end

  @doc """
  Zero dependency, super lightweight HTTP server for purposes of responding to the ACME http-01 challenge. This is only meant to
  be used if you're running in an environment where cowboy/plug are not already running - in which case, you're better off using
  the plug.
  """
  def listen(account_key) do
    {:ok, socket} = :gen_tcp.listen(8080, [:binary, packet: :http, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port")

    accept(socket, account_key)
  end

  def accept(socket, account_key) do
    case do_accept(socket, account_key) do
      :ok -> accept(socket, account_key)
      _ -> accept(socket, account_key)
    end
  end

  def do_accept(socket, account_key) do
    {:ok, client} = :gen_tcp.accept(socket)

    response =
      read_request(client)
      |> IO.inspect()
      |> handle_challenge(account_key)
      |> IO.inspect()
      |> write_response(client)

    :gen_tcp.close(client)

    response
  end

  def read_request(client) do
    {:ok, {:http_request, method, {:abs_path, path}, _version}} = :gen_tcp.recv(client, 0)
    req_headers = get_headers(client)
    host = Enum.find(req_headers, fn header -> header == "host" end)

    %{method: to_string(method), req_headers: req_headers, host: host, request_path: to_string(path)}
  end

  def write_response({:ok, token}, client) do
    :inet.setopts(client, packet: :raw)

    :gen_tcp.send(client, "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/html\r\n\r\n#{token}")
    :gen_tcp.close(client)

    :ok
  end

  def write_response({:error, _}, client) do
    :inet.setopts(client, packet: :raw)

    :gen_tcp.send(client, "HTTP/1.1 400 BAD REQUEST\r\nConnection: close\r\nContent-Type: text/html\r\n\r\nBad Request")
    :gen_tcp.close(client)

    :error
  end

  def get_headers(client, headers \\ []) do
    case :gen_tcp.recv(client, 0, 60000) do
      {:ok, {:http_header, _, _, key, value}} -> get_headers(client, [{to_string(key) |> String.downcase(), to_string(value)} | headers])
      {:ok, :http_eoh} -> headers
    end
  end
end
