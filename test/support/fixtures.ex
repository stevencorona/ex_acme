defmodule ExAcme.Fixtures do
  def fixture!(:new_account) do
    %Tesla.Env{
      method: :post,
      url: "https://acme-staging-v02.api.letsencrypt.org/acme/acct/12345",
      body: %{
        created_at: "2023-05-02T12:56:07Z",
        initial_ip: "127.0.0.1",
        key: %{
          crv: "P-384",
          kty: "EC",
          x: "awI6z3kr1EspWz2dUhnHzx0GxxFBr2YLATzzqB15D_-9stJcF_VX12I6Knotp9DP",
          y: "lFsi_HMiMnZTM9A9eOOulAxwiK5mop6crjAypQMF3EZdREbZiNIFW8y5Ti2n2Bp3"
        },
        status: "valid"
      },
      status: 200
    }
  end
end
