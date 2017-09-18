defmodule Adyen.PaymentNotificationTest do
  use ExUnit.Case

  test "it can parse a notification" do
    assert {:ok, notification} = Adyen.PaymentNotification.parse(
             %{
               "additionalData.bic" => "TESTNL01",
               "additionalData.iban" => "NL13TEST0123456789",
               "additionalData.issuerCountry" => "unknown",
               "additionalData.ownerName" => "A. Klaassen",
               "additionalData.shopperIP" => "127.0.0.1",
               "currency" => "EUR",
               "authResult" => "AUTHORISED",
               "eventCode" => "AUTHORISATION",
               "eventDate" => "2017-06-14T08:36:51.42Z",
               "live" => "false",
               "merchantAccountCode" => "BondsPlatform",
               "merchantReference" => "25ddeb63-f693-45f2-b07e-6f71b041c8cc",
               "operations" => "REFUND",
               "originalReference" => "",
               "paymentMethod" => "ideal",
               "pspReference" => "8514974294043640",
               "reason" => "",
               "success" => "true",
               "value" => "100000"
             }
           )

    assert %{
      account_owner_name: "A. Klaassen",
      amount_in_cents: 100000,
      bic: "TESTNL01",
      currency: "EUR",
      event_code: "AUTHORISATION",
      event_date: "2017-06-14T08:36:51.42Z",
      iban: "NL13TEST0123456789",
      ip: "127.0.0.1",
      live: false,
      merchant_account_code: "BondsPlatform",
      merchant_reference: "25ddeb63-f693-45f2-b07e-6f71b041c8cc",
      operations: "REFUND",
      original_reference: nil,
      payment_method: "ideal",
      payment_state: "AUTHORISED",
      psp_reference: "8514974294043640",
      reason: nil,
      success: true
    } = notification
  end
end
