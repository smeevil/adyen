#https://docs.adyen.com/developers/api-reference/hosted-payment-pages-api#hpppaymentrequest
defmodule Adyen.Options do
  @moduledoc """
  This module will validate and format all options that can be passed to adyen
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "options" do
    field :amount_in_cents, :integer
    field :currency, :string
    field :reference, :string
    field :country_iso, :string
    field :merchant_account, :string
    field :session_validity, :string
    field :skin_code, :string
    field :signature, :string
    field :method, :string
    field :issuer_id, :integer
    field :hmac_key, :string
    field :return_url, :string
  end

  @required_fields [
    :amount_in_cents,
    :currency,
    :hmac_key,
    :merchant_account,
    :reference,
    :session_validity,
    :skin_code
  ]

  @optional_fields [:issuer_id, :method, :return_url]

  @field_mapping [
    amount_in_cents: "paymentAmount",
    country_iso: "countryCode",
    currency: "currencyCode",
    issuer_id: "issuerId",
    merchant_account: "merchantAccount",
    method: "brandCode",
    reference: "merchantReference",
    session_validity: "sessionValidity",
    skin_code: "skinCode",
    return_url: "resURL"
  ]

  #TODO implement these fields
  # merchantReturnData : This field value is appended as-is to the return URL when the shopper completes, or abandons, the payment process and is redirected to your web shop. Typically, this field is used to hold and transmit a session ID.

  @doc """
  Use this to create the Adyen.Options struct which will validate all parameters given.
  """
  @spec create(params :: map | list) :: {:ok, %Adyen.Options{}} | {:error, Ecto.Changeset.t}
  def create(params \\ %{})
  def create(params) when is_list(params), do: create(Enum.into(params, %{}))
  def create(params) do
    case payment_changeset(%Adyen.Options{}, params) do
      %{valid?: true} = changeset -> {:ok, Ecto.Changeset.apply_changes(changeset)}
      changeset -> {:error, Enum.map(changeset.errors, fn ({field, {msg, _}}) -> {field, msg} end)}
    end
  end

  @doc """
  Use this if you only need to validate / use credentials for your paynl account
  """
  @spec credentials(params :: map | list) :: {:ok, %Adyen.Options{}} | {:error, Ecto.Changeset.t}
  def credentials(params \\ %{})
  def credentials(params) when is_list(params), do: credentials(Enum.into(params, %{}))
  def credentials(params) do
    case credentials_changeset(params) do
      %{valid?: true} = changeset -> {:ok, Ecto.Changeset.apply_changes(changeset)}
      changeset -> {:error, Enum.map(changeset.errors, fn ({field, {msg, _}}) -> {field, msg} end)}
    end
  end

  @doc """
  Will convert the Adyen.Options struct to a map which can then be submitted through http post
  """
  @spec to_post_map(options :: %Adyen.Options{}) :: map
  def to_post_map(%Adyen.Options{} = options) do
    options
    |> Map.from_struct
    |> Map.delete(:__meta__)
    |> process_options(@field_mapping)
    |> Adyen.Client.Hmac.sign
  end

  @doc """
  Will convert the Adyen.Options struct to a URI encoded query_string which can then be attached to a get path request
  """
  @spec to_query_string(options :: %Adyen.Options{}) :: String.t
  def to_query_string(%Adyen.Options{} = options) do
    options
    |> to_post_map
    |> URI.encode_query
  end

  @spec credentials_changeset(params :: map) :: Ecto.Changeset.t
  defp credentials_changeset(params) do
    params = add_defaults(params)

    %Adyen.Options{}
    |> cast(params, @required_fields)
    |> validate_required_config_settings
    |> validate_required(@required_fields)
  end

  @spec payment_changeset(struct :: %Adyen.Options{}, params :: map) :: Ecto.Changeset.t
  defp payment_changeset(struct, params) do
    #TODO add more friendly messages for all config values
    params = add_defaults(params)
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required_config_settings
    |> validate_required(@required_fields)
    |> validate_number(:amount_in_cents, greater_than_or_equal_to: 0)
    |> maybe_validate_issuer_id
  end

  @spec add_defaults(params :: map) :: map
  defp add_defaults(params) do
    params
    |> Map.put_new(
         :merchant_account,
         System.get_env("ADYEN_MERCHANT_ACCOUNT") || Application.get_env(:adyen, :merchant_account)
       )
    |> Map.put_new(:hmac_key, System.get_env("ADYEN_HMAC_KEY") || Application.get_env(:adyen, :hmac_key))
    |> Map.put_new(:skin_code, System.get_env("ADYEN_SKIN_CODE") || Application.get_env(:adyen, :skin_code))
    |> Map.put_new(:reference, Ecto.UUID.generate())
    |> Map.put_new(:session_validity, Adyen.Helpers.TimeHelpers.formatted_minutes_from_now(30))
    |> Map.put_new(:method, "ideal")
    |> Map.put_new(:country_iso, "NL")
    |> Map.put_new(:currency, "EUR")
  end

  @spec process_options(options :: map, mapping :: list({atom, binary}), data :: map) :: map
  defp process_options(options, mapping, data \\ %{})
  defp process_options(_options, [], data), do: data
  defp process_options(options, [{key, mapped} | tail], data) do
    data = case Map.get(options, key) do
      nil -> data
      value -> Map.put(data, mapped, convert_value(value))
    end
    process_options(options, tail, data)
  end

  @spec convert_value(value :: boolean | any) :: true | false | any
  defp convert_value(true), do: "1"
  defp convert_value(false), do: "0"
  defp convert_value(value), do: value

  @spec maybe_validate_issuer_id(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  defp maybe_validate_issuer_id(
         %{
           changes: %{
             issuer_id: issuer_id
           }
         } = changeset
       ) do
    {:ok, ids} = Adyen.issuer_ids
    if Enum.member?(ids, issuer_id) do
      changeset
    else
      add_error(changeset, :issuer_id, "#{issuer_id} is an invalid issuer id, must be one of #{Enum.join(ids, ", ")}")
    end
  end
  defp maybe_validate_issuer_id(changeset), do: changeset

  @spec validate_required_config_settings(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  defp validate_required_config_settings(changeset) do
    changeset
    |> validate_required(
         :merchant_account,
         message: ~s[has not been set, either pass it along with the params in this function as :merchant_account, alternatively you can pass it by defining an env var 'ADYEN_MERCHANT_ACCOUNT=my_merchant_account' or in you config add 'config :adyen, merchant_account: "my_marchant_account"']
       )
    |> validate_required(
         :skin_code,
         message: ~s[has not been set, either pass it along with the params in this function as :skin_code, alternatively you can pass it by defining an env var 'ADYEN_SKIN_CODE=my_skin_code' or in you config add 'config :adyen, skin_code: "my_skin_code"']
       )
    |> validate_required(
         :hmac_key,
         message: ~s[has not been set, either pass it along with the params in this function as :hmac, alternatively you can pass it by defining an env var 'ADYEN_HMAC_KEY=my_hmac_key' or in you config add 'config :adyen, hmac_key: "my_hmac_key"']
       )
  end
end