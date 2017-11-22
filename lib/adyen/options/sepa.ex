#https://docs.adyen.com/developers/api-reference/hosted-payment-pages-api#hpppaymentrequest
defmodule Adyen.Options.Sepa do
  @moduledoc """
  This module will validate and format all options that can be passed to adyen
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "options" do
    field :amount_in_cents, :integer
    field :basic_auth_password, :string
    field :basic_auth_username, :string
    field :country_iso, :string
    field :currency, :string
    field :email, :string
    field :iban, :string
    field :merchant_account, :string
    field :method, :string
    field :owner, :string
    field :reference, :string
    field :remote_ip, :string
    field :statement, :string
  end

  @required_fields [
    :amount_in_cents,
    :basic_auth_password,
    :basic_auth_username,
    :country_iso,
    :currency,
    :iban,
    :merchant_account,
    :method,
    :owner,
    :reference,
    :remote_ip,
    :statement,
  ]

  @optional_fields [:email]


  @doc """
  Use this to create the Adyen.Options.Sepa struct which will validate all parameters given.
  """
  @spec create(params :: map | list) :: {:ok, %Adyen.Options{}} | {:error, Ecto.Changeset.t}
  def create(params \\ %{})
  def create(params) when is_list(params), do: create(Enum.into(params, %{}))
  def create(params) do
    case changeset(%Adyen.Options.Sepa{}, params) do
      %{valid?: true} = changeset -> {:ok, Ecto.Changeset.apply_changes(changeset)}
      changeset -> {:error, Enum.map(changeset.errors, fn ({field, {msg, _}}) -> {field, msg} end)}
    end
  end

  @spec changeset(struct :: %Adyen.Options.Sepa{}, params :: map) :: Ecto.Changeset.t
  defp changeset(struct, params) do
    params = add_defaults(params)
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required_config_settings
    |> validate_required(@required_fields)
    |> validate_number(:amount_in_cents, greater_than_or_equal_to: 0)
  end

  @doc """
  Will convert the Adyen.Options struct to a map which can then be submitted through http post
  """
  @spec to_post_map(options :: %Adyen.Options.Sepa{}) :: map
  def to_post_map(%Adyen.Options.Sepa{} = options) do
      %{
        bankAccount: %{
          iban: options.iban,
          ownerName: options.owner,
          countryCode: options.country_iso
        },
        amount: %{
          value: options.amount_in_cents,
          currency: options.currency
        },
        reference: options.reference,
        merchantAccount: options.merchant_account,
        shopperEmail: options.email,
        shopperIP: options.remote_ip,
        shopperStatement: options.statement,
        selectedBrand: options.method
      }
  end

  @spec add_defaults(params :: map) :: map
  defp add_defaults(params) do
    params
    |> Map.put_new(
         :merchant_account,
         System.get_env("ADYEN_MERCHANT_ACCOUNT") || Application.get_env(:adyen, :merchant_account)
       )
    |> Map.put_new(
         :basic_auth_username,
         System.get_env("ADYEN_BASIC_AUTH_USERNAME") || Application.get_env(:adyen, :basic_auth_username)
       )
    |> Map.put_new(
         :basic_auth_password,
         System.get_env("ADYEN_BASIC_AUTH_PASSWORD") || Application.get_env(:adyen, :basic_auth_password)
       )
    |> Map.put_new(:reference, Ecto.UUID.generate())
    |> Map.put_new(:method, "sepadirectdebit")
    |> Map.put_new(:country_iso, "NL")
    |> Map.put_new(:currency, "EUR")
  end

  @spec validate_required_config_settings(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  defp validate_required_config_settings(changeset) do
    changeset
    |> validate_required(
         :merchant_account,
         message: ~s[has not been set, either pass it along with the params in this function as :merchant_account, alternatively you can pass it by defining an env var 'ADYEN_MERCHANT_ACCOUNT=my_merchant_account' or in your config add 'config :adyen, merchant_account: "my_marchant_account"']
       )
    |> validate_required(
         :basic_auth_username,
         message: ~s[has not been set, either pass it along with the params in this function as :basic_auth_username, alternatively you can pass it by defining an env var 'ADYEN_BASIC_AUTH_USERNAME=my_username' or in your config add 'config :adyen, basic_auth_username: "my_username"']
       )
    |> validate_required(
         :basic_auth_password,
         message: ~s[has not been set, either pass it along with the params in this function as :basic_auth_password, alternatively you can pass it by defining an env var 'ADYEN_BASIC_AUTH_PASSWORD=my_password' or in your config add 'config :adyen, basic_auth_password: "my_password"']
       )
  end
end