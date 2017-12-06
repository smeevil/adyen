defmodule Adyen do
  @moduledoc """
  This modile will wrap all implemented functions for adyen
  """

  defdelegate capture_payment(options), to: Adyen.Client

  def request_capture(params) do
    case Adyen.Options.create(params) do
      {:ok, options} -> Adyen.Client.request_capture(options)
      error -> error
    end
  end

  def request_sepa_capture(params) do
    case Adyen.Options.SepaOptions.create(params) do
      {:ok, options} -> Adyen.Client.request_sepa_capture(options)
      error -> error
    end
  end

  def banks, do: GenServer.call(Adyen.BanksCache, {:get_banks})
  def issuer_ids, do: GenServer.call(Adyen.BanksCache, {:get_issuer_ids})

end
