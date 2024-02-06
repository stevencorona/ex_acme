defmodule ExAcme.Utils do
  def take_camelized(map, keys) do
    Map.take(map, keys) |> Enum.map(fn {k, v} -> {Atom.to_string(k) |> Macro.camelize(), v} end) |> Enum.into(%{})
  end

  def api(%{api_adapter: adapter}) when not is_nil(adapter), do: adapter
  def api(adapter: adapter) when not is_nil(adapter), do: adapter
  def api(_), do: ExAcme.Api

  def to_struct(%Tesla.Env{body: body} = env), do: Map.put_new(body, :location, Tesla.get_header(env, "location")) |> to_struct()
  def to_struct(attrs), do: struct!(__MODULE__, attrs)
  def to_struct(attrs, extra), do: to_struct(attrs) |> Map.merge(Enum.into(extra, %{}))

  def update_struct(struct, env), do: %{to_struct(env) | location: struct.location}
end

defimpl Jason.Encoder, for: ExAcme.Account do
  def encode(value, opts) do
    value
    |> ExAcme.Utils.take_camelized([:contact, :terms_of_service_agreed, :only_return_existing])
    |> Jason.Encode.map(opts)
  end
end
