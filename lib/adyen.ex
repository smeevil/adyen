defmodule Adyen do
  @moduledoc """
  This modile will wrap all implemented functions for adyen
  """

  defdelegate capture_payment(options), to: Adyen.Client

  @doc "Returns a redirect url to adyen to complete the payment"
  @spec request_redirect_url(map) :: {:ok, binary}
  def request_redirect_url(params) do
    case Adyen.Options.create(params) do
      {:ok, options} -> Adyen.Client.request_redirect_url(options)
      error -> error
    end
  end

  @doc "Will request a sepa capture and returns a capture response with all the information that you might need for a capture later in the process"
  @spec request_sepa_capture(map) :: {:ok, %Adyen.CaptureRequestResponse{}} | {:error, any}
  def request_sepa_capture(params) do
    case Adyen.Options.SepaOptions.create(params) do
      {:ok, sepa_options} -> Adyen.Client.request_sepa_capture(sepa_options)
      error -> error
    end
  end

  @doc "Will perform an immediate capture using sepa"
  @spec direct_sepa_capture(map) :: {:ok, non_neg_integer} | {:error, any}
  def direct_sepa_capture(params) do
    with {:ok, request_response} <- Adyen.request_sepa_capture(params),
         {:ok, reference} <- Adyen.capture_payment(request_response)
      do
      {:ok, reference}
    end
  end

  @doc "returns a list of banks"
  @spec banks :: {:ok, [map]}
  def banks, do: GenServer.call(Adyen.BanksCache, {:get_banks})

  @doc "returns a list of issuer_ids"
  @spec issuer_ids :: {:ok, [number]}
  def issuer_ids, do: GenServer.call(Adyen.BanksCache, {:get_issuer_ids})

end
