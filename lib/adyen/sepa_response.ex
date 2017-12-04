defmodule Adyen.SepaResponse do
  @moduledoc """
  Converts the params from a sepa respons back to a struct and casts the values
  """

  defstruct [:signed_at, :mandate_id, :sequence_type, :reference, :result]

  @spec parse({:ok, map}) :: {:ok, %Adyen.SepaResponse{}} | {:error, map}
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
        }
      ) do
    {
      :ok,
      %Adyen.SepaResponse{
        signed_at: Date.from_iso8601!(signed_at),
        mandate_id: String.to_integer(mandate_id),
        sequence_type: sequence_type,
        reference: String.to_integer(reference),
        result: result,
      }
    }
  end
  def parse({_, data}) do
    {:error, data}
  end
end
