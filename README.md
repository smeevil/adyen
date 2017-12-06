# Adyen

Adyen is an Elixir library that wraps the adyen.com api for making
payments.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `adyen` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:adyen, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/adyen](https://hexdocs.pm/adyen).

## Settings
Adyen requires the API credentials of your Adyen account. You can define
either as ENV settings using the keys :
- `ADYEN_MERCHANT_ACCOUNT`
- `ADYEN_SKIN_CODE`
- `ADYEN_HMAC_KEY`

or in your config.exs using :

```elixir
  config :adyen,
    merchant_account: "my-merchant-account",
    skin_code: "my-skin-code",
    hmac_key: "my-hmac-key"
```

## Usage

To get a list of supported banks for your credentials, you can use:

```elixir
iex> Adyen.banks
{:ok,
 [%{issuer_id: 1121, name: "Test Issuer"},
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
}
```

To return a list of issuer id's you can use :

```elixir
iex> Adyen.issuer_ids
{:ok, [1121, 1154, 1153, 1152, 1151, 1162, 1161, 1160, 1159, 1158, 1157, 1156, 1155]}
```

To request a payment and let the user pick a bank at adyen's page:

```elixir
iex> Adyen.request_capture(amount_in_cents: 10000)
{:ok, "https://test.adyen.com/hpp/pay.shtml?brandCode=ideal&currencyCode=EUR&merchantAccount=BondsPlatform&merchantReference=64b6785d-3bfc-4df5-98f4-9ee6c122e48a&merchantSig=wtrHpjhykN5lIBkMKscOh6%2BgBJbJTtHRQGGJF86oZbw%3D&paymentAmount=10000&sessionValidity=2017-10-03T13%3A30%3A18%2B00%3A00&skinCode=Y5mxfUVI"}
```

To request a payment with a pre-picked bank:
```elixir
iex> Adyen.request_capture(amount_in_cents: 10000, issuer_id: 1121)
{:ok, "https://test.adyen.com/hpp/skipDetails.shtml?brandCode=ideal&currencyCode=EUR&issuerId=1121&merchantAccount=BondsPlatform&merchantReference=08b69494-97fa-41c2-a637-fcdebf53bf55&merchantSig=1B6ahlrK7nQc11oQxy9w2FU9N8HPRJL1YezDDxP5BZg%3D&paymentAmount=10000&sessionValidity=2017-10-03T13%3A32%3A07%2B00%3A00&skinCode=Y5mxfUVI"}
```

Take note, by default the payment method selected is Ideal and the
currency is set to EUR. You can change these settings while making the
Adyen.request_capture/1 call. See Adyen.Options for all possible options.
