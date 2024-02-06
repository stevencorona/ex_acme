defmodule ExAcme.Challenge do
  defstruct [:status, :token, :type, :url, :error, :validated, :expires, validation_record: []]

  # Defining these so that String.to_existing_atom() is happy
  @empty_validation_record [:address_used, :addresses_resolved, :hostname, :port, :url]
end
