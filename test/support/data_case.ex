defmodule ExAcme.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import ExAcme.Fixtures
    end
  end
end
