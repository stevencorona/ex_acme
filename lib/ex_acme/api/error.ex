defmodule ExAcme.Error do
  defstruct [:detail, :type, :status]

  def build_error(env) do
    error = struct!(__MODULE__, env)
    {type_to_atom(error.type), error}
  end

  def type_to_atom("urn:ietf:params:acme:error:orderNotReady"), do: :order_not_ready
  def type_to_atom("urn:ietf:params:acme:error:unauthorized"), do: :unauthorized
  def type_to_atom("urn:ietf:params:acme:error:accountDoesNotExist"), do: :account_not_exist
  def type_to_atom(_), do: :unknown
end
