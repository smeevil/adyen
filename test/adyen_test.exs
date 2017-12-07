defmodule AdyenTest do
  use ExUnit.Case

  test "it returns a list of banks" do
    assert {
             :ok,
             [
               %{issuer_id: 1121, name: "Test Issuer"},
               %{issuer_id: 1154, name: "Test Issuer 5"},
               %{issuer_id: 1153, name: "Test Issuer 4"},
               %{issuer_id: 1152, name: "Test Issuer 3"},
               %{issuer_id: 1151, name: "Test Issuer 2"},
               %{issuer_id: 1162, name: "Test Issuer Cancelled"},
               %{issuer_id: 1161, name: "Test Issuer Pending"},
               %{issuer_id: 1160, name: "Test Issuer Refused"},
               %{issuer_id: 1159, name: "Test Issuer 10"},
               %{issuer_id: 1158, name: "Test Issuer 9"},
               %{issuer_id: 1157, name: "Test Issuer 8"},
               %{issuer_id: 1156, name: "Test Issuer 7"},
               %{issuer_id: 1155, name: "Test Issuer 6"}
             ]
           } = Adyen.banks()
  end

  test "it returns a list of bank issuers" do
    assert {
             :ok,
             [
               1121,
               1154,
               1153,
               1152,
               1151,
               1162,
               1161,
               1160,
               1159,
               1158,
               1157,
               1156,
               1155
             ]
           } = Adyen.issuer_ids()
  end

  test "it returns a redirect url to adyen where you can select a bank" do
    assert {
             :ok,
             "https://test.adyen.com/hpp/pay.shtml?brandCode=ideal&currencyCode=EUR" <> _rest
           } = Adyen.request_redirect_url(amount_in_cents: 10000)
  end

  test "it returns a redirect url to adyen with a preselected bank" do
    assert {
             :ok,
             "https://test.adyen.com/hpp/skipDetails.shtml?brandCode=ideal&currencyCode=EUR&issuerId=1151" <> _rest
           }
           = Adyen.request_redirect_url(amount_in_cents: 10000, issuer_id: 1151)
  end

  test "it returns a redirect url to adyen for a SEPA payment" do
    assert {
             :ok,
             "https://test.adyen.com/hpp/pay.shtml?brandCode=sepadirectdebit&currencyCode=EUR" <> _rest
           } = Adyen.request_redirect_url(amount_in_cents: 10000, method: "sepadirectdebit")
  end

  test "it needs at last an amount in cents" do
    assert {:error, [amount_in_cents: "can't be blank"]} = Adyen.request_redirect_url(%{})
  end

  #    FIXME outdated info, need a new map to verify
  #    test "hmac authenticVity" do
  #      #these parameters came from a return url after payment has been done.
  #      assert %{
  #               "authResult" => "AUTHORISED",
  #               "merchantReference" => "25ddeb63-f693-45f2-b07e-6f71b041c8cc",
  #               "merchantSig" => "tNMZpG8zkwTsB0yhvArhIO+Q1raEC/9+zBp25kX/sT0=",
  #               "paymentMethod" => "ideal",
  #               "pspReference" => "8815057372964667",
  #               "shopperLocale" => "en_GB",
  #               "skinCode" => "Y5mxfUVI"
  #             }
  #             |> Adyen.Client.Hmac.authentic_response?
  #    end

  test "it can request a sepa capture" do
    assert {
             :ok,
             %Adyen.CaptureRequestResponse{
               capture_info: %{
                 account: _account,
                 amount: %{
                   currency: "EUR",
                   value: 100
                 },
                 basic_auth_password: _password,
                 basic_auth_username: _username,
                 original_reference: _ref1
               },
               mandate_id: _ref2,
               reference: _ref3,
               result: "Received",
               sequence_type: "OneOff",
               signed_at: %Date{}
             }
           } = Adyen.request_sepa_capture(
             %{
               amount_in_cents: 100,
               email: "shopper@example.com",
               iban: "NL13TEST0123456789",
               owner: "Test User",
               remote_ip: "127.0.0.1",
               statement: "Order of Test Item",
               recurring: true
             }
           )
  end

  test "it can handle a sepa payment error" do
    assert {
             :error,
             [
               amount_in_cents: "can't be blank",
               iban: "can't be blank",
               owner: "can't be blank",
               remote_ip: "can't be blank",
               statement: "can't be blank",
               recurring: "can't be blank"
             ]
           } == Adyen.request_sepa_capture(%{})
  end

  test "it can capture a sepa payment" do
    {:ok, %Adyen.CaptureRequestResponse{} = request_response} = Adyen.request_sepa_capture(
      %{
        amount_in_cents: 100,
        email: "shopper@example.com",
        iban: "NL13TEST0123456789",
        owner: "Test User",
        remote_ip: "127.0.0.1",
        statement: "Order of Test Item",
        recurring: true
      }
    )

    assert {:ok, _ref, } = Adyen.capture_payment(request_response)
  end

  test "it can make an direct capture via sepa" do
    assert {:ok, _ref} = Adyen.direct_sepa_capture(%{
            amount_in_cents: 100,
            email: "shopper@example.com",
            iban: "NL13TEST0123456789",
            owner: "Test User",
            remote_ip: "127.0.0.1",
            statement: "Order of Test Item",
            recurring: true
          })
  end


  test "it can validate ibans" do
    assert {:error, [iban: "is invalid"]} = Adyen.direct_sepa_capture(%{
             amount_in_cents: 100,
             email: "shopper@example.com",
             iban: "NL01TEST0123456789",
             owner: "Test User",
             remote_ip: "127.0.0.1",
             statement: "Order of Test Item",
             recurring: true
           })
  end
end
