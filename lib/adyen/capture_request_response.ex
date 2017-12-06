defmodule Adyen.CaptureRequestResponse do
  @moduledoc """
  Converts the params from a sepa respons back to a struct and casts the values
  """

  defstruct [:signed_at, :mandate_id, :sequence_type, :reference, :result, :capture_info]

  @spec parse({:ok, map} | {:error, any}, %Adyen.Options.SepaOptions{}) :: {:ok, %Adyen.CaptureRequestResponse{}} | {:error, map}
  def parse({:error, _} = error, _options), do: error
  def parse(
        {
          :ok,
          %{
            "additionalData" => %{
              "sepadirectdebit.dateOfSignature" => signed_at,
              "sepadirectdebit.mandateId" => mandate_id,
              "sepadirectdebit.sequenceType" => sequence_type,
            },
            "pspReference" => reference,
            "resultCode" => result
          }
        },
        sepa_options
      ) do
    {
      :ok,
      %Adyen.CaptureRequestResponse{
        signed_at: Date.from_iso8601!(signed_at),
        mandate_id: String.to_integer(mandate_id),
        sequence_type: sequence_type,
        reference: String.to_integer(reference),
        result: result,
        capture_info: %{
          basic_auth_username: sepa_options.basic_auth_username,
          basic_auth_password: sepa_options.basic_auth_password,
          account: sepa_options.merchant_account,
          amount: %{
            value: sepa_options.amount_in_cents,
            currency: sepa_options.currency
          },
          original_reference: String.to_integer(reference)
        }
      }
    }
  end
end
