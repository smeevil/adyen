defmodule Adyen do
  @moduledoc """
  This modile will wrap all implemented functions for adyen
  """

  def request_payment(params) do
    case Adyen.Options.create(params) do
      {:ok, options} -> Adyen.Client.request_payment(options)
      error -> error
    end
  end

  def banks, do: GenServer.call(Adyen.BanksCache, {:get_banks})
  def issuer_ids, do: GenServer.call(Adyen.BanksCache, {:get_issuer_ids})

end
