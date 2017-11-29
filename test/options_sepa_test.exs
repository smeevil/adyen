defmodule Adyen.Options.SepaTest do
  use ExUnit.Case

  @valid_params %{
    amount_in_cents: 100,
    email: "shopper@example.com",
    iban: "NL13TEST0123456789",
    owner: "Test User",
    remote_ip: "127.0.0.1",
    statement: "Order of Test Item"
  }

  test "it can create a changeset with errors" do
    assert {
             :error,
             [
               amount_in_cents: "can't be blank",
               iban: "can't be blank",
               owner: "can't be blank",
               remote_ip: "can't be blank",
               statement: "can't be blank"
             ]
           } == Adyen.Options.Sepa.create()
  end

  test "it can create a changeset" do
    assert {:ok, %Adyen.Options.Sepa{}} = Adyen.Options.Sepa.create(@valid_params)
  end

  test "it can convert options to json" do
    {:ok, sepa_options} = Adyen.Options.Sepa.create(@valid_params)
    assert  %{
              amount: %{
                currency: "EUR",
                value: 100
              },
              bankAccount: %{
                countryCode: "NL",
                iban: "NL13TEST0123456789",
                ownerName: "Test User"
              },
              merchantAccount: "MijndomeinVPSShop",
              reference: _ref,
              selectedBrand: "sepadirectdebit",
              shopperEmail: "shopper@example.com",
              shopperIP: "127.0.0.1",
              shopperStatement: "Order of Test Item"
            } = Adyen.Options.Sepa.to_post_map(sepa_options)
  end


end
