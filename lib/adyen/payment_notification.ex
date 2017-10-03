defmodule Adyen.PaymentNotification do
  @moduledoc """
  This module will validate and format incoming payment notifications
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "options" do
    field :account_owner_name, :string
    field :amount_in_cents, :integer
    field :bic, :string
    field :currency, :string
    field :event_code, :string
    field :event_date, :string
    field :iban, :string
    field :ip, :string
    field :live, :boolean
    field :merchant_account_code, :string
    field :merchant_reference, :string
    field :operations, :string
    field :original_reference, :string
    field :payment_method, :string
    field :payment_state, :string
    field :psp_reference, :string
    field :reason, :string
    field :success, :boolean
  end

  @required_fields [:event_code, :live]

  @optional_fields [
    :account_owner_name,
    :amount_in_cents,
    :bic,
    :currency,
    :event_code,
    :event_date,
    :iban,
    :ip,
    :merchant_account_code,
    :merchant_reference,
    :operations,
    :original_reference,
    :payment_method,
    :payment_state,
    :psp_reference,
    :reason,
    :success
  ]

  @valid_event_codes [
    "AUTHORISED",
    # The payment authorisation was successfully completed.
    "REFUSED",
    # The payment was refused. Payment authorisation was unsuccessful.
    "CANCELLED",
    # The payment was cancelled by the shopper before completion, or the shopper returned to the merchant's site before completing the transaction.
    "PENDING",
    # It is not possible to obtain the final status of the payment. This can happen if the systems providing final status information for the payment are unavailable, or if the shopper needs to take further action to complete the payment.
    "ERROR",
    # An error occurred during the payment processing.
    "AUTHORISATION",
    #he result of an authorised transaction is returned in this notification.
    "CANCELLATION",
    #he result of a cancel modification is returned in this notification.
    "REFUND",
    #he result of a refund modification is returned in this notification.
    "CANCEL_OR_REFUND",
    #he result of a refund or cancel modification is returned in this notification.
    "CAPTURE",
    #he result of a capture modification is returned in this notification.
    "CAPTURE_FAILED",
    # * )	Whenever a capture failed after it was processed by the third party we return this notification. It means that there was a technical issue which should be investigated. Most of the times it needs to be retried to make it work.
    "REFUND_FAILED",
    # * )Whenever a refund failed after it was processed by the third party we return this notification. It means that there was a technical issue, which should be investigated. Most of the times it needs to be retried to make it work.
    "REFUNDED_REVERSED",
    # * )	When we receive back the funds from the bank we book the transaction to Refunded Reversed. This can happen if the card is closed.
    "PAIDOUT_REVERSED",
    # * ) When we receive back the funds because it couldn't be paid to the shopper, we book the transaction to PaidOutReversed.
    "VOID_PENDING_REFUND",
    #pplicable to POS only. The voidPendingRefund service attempts to cancel a POS refund request. The final outcome will be reported through notifications.
    "POSTPONED_REFUND",
    #he refund will be performed after the payment is captured.
    "REQUEST_FOR_INFORMATION",
    # * )	Whenever a shopper opens an RFI (Request for Information) case with the bank we will send this notification. You should upload defense material, which gives the information to the shopper to understand the charge.
    "CHARGEBACK",
    # * )	Whenever the funds are deducted, we send out the chargeback notification.
    "CHARGEBACK_REVERSED",
    # * ) This is triggered when the funds are returned to your account we send out the chargeback_reversed notification.
    "NOTIFICATION_OF_CHARGEBACK",
    # * ) Whenever a real dispute case is opened this is the first notification in the process, which you receive. This is the start point to look into the dispute and upload defense material.
    "NOTIFICATION_OF_FRAUD",
    # * )	This notification lists the transaction that has been reported as Fraudulent by the schemes. This is only the case if a chargeback is received (which is sent out separately). Use this notification, for example, to identify fraudulent transactions with 3D Secure liability shift, which are not (and may not be) chargeback.
    "MANUAL_REVIEW_ACCEPT",
    # * )	Notification for acceptance of manual review.
    "MANUAL_REVIEW_REJECT",
    # * )	Notification for rejection of manual review.
    "RECURRING_CONTRACT",
    #otification for the creation of a recurring contract.
    "PAYOUT_EXPIRE",
    # * )	Notification when a payout expires.
    "PAYOUT_DECLINE",
    # * )	Notification when a payout is declined.
    "PAYOUT_THIRDPARTY",
    #otification when a third party payout is processed.
    "REFUND_WITH_DATA",
    #otification when a refund with data or payout is processed.
    "AUTHORISE_REFERRAL",
    #otification when a referral is authorised.
    "FRAUD_ONLY",
    # * )	Notification for a fraud transaction.
    "FUND_TRANSFER",
    #otification for a fund transfer from your account to the shopper's account.
    "HANDLED_EXTERNALLY",
    # * )	Notification if a payment is handled outside the Adyen system.
    "OFFER_CLOSED",
    # * )	Notification when an offer is closed.
    "ORDER_OPENED",
    # * )	Notification when an order is created.
    "ORDER_CLOSED",
    # * ) This notification is sent in case of partial payments when all the transactions for the order are complete.
    "PENDING",
    # * )	Notification when the transaction is pending.
    "PROCESS_RETRY",
    # * )	Notification when an idempotent request is processed.
    "REPORT_AVAILABLE",
    # * )	Every time Adyen's system generates a report, we send out the notification which includes the url which can be used to automatically retrieve the notification
  ]

  @valid_payment_states [
    "AUTHORISED",
    #The payment authorisation was successfully completed.
    "REFUSED",
    #The payment was refused. Payment authorisation was unsuccessful.
    "CANCELLED",
    #The payment was cancelled by the shopper before completion, or the shopper returned to the merchant's site before completing the transaction.
    "PENDING",
    #It is not possible to obtain the final status of the payment.
    "ERROR",
    #An error occurred during the payment processing.
  ]

  @mapping %{
    "additionalData.bic" => :bic,
    "additionalData.iban" => :iban,
    "additionalData.ownerName" => :account_owner_name,
    "additionalData.shopperIP" => :ip,
    "currency" => :currency,
    "authResult" => :payment_state,
    "eventCode" => :event_code,
    "eventDate" => :event_date,
    "live" => :live,
    "merchantAccountCode" => :merchant_account_code,
    "merchantReference" => :merchant_reference,
    "operations" => :operations,
    "originalReference" => :original_reference,
    "paymentMethod" => :payment_method,
    "pspReference" => :psp_reference,
    "reason" => :reason,
    "success" => :success,
    "value" => :amount_in_cents
  }
  @spec parse(map) :: {:ok, %Adyen.PaymentNotification{}} | {:error, list}
  def parse(params \\ %{}) do
    changeset = %Adyen.PaymentNotification{}
    |> cast(map_params(params), @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:payment_state, @valid_payment_states)
    |> validate_inclusion(:event_code, @valid_event_codes)

    if changeset.valid? do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    else
      {:error, changeset.errors}
    end
  end

  @spec map_params(map) :: map
  defp map_params(params) do
    params
    |> Enum.map(fn {k, v} -> {Map.get(@mapping, k), normalize_value(v)} end)
    |> Enum.into(%{})
  end

  @spec normalize_value(String.t | any) :: boolean | any
  defp normalize_value("true"), do: true
  defp normalize_value("false"), do: false
  defp normalize_value("1"), do: true
  defp normalize_value("0"), do: false
  defp normalize_value(value), do: value
end
