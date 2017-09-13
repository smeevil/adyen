defmodule Adyen.Client.Hmac do
  @moduledoc """
  This module takes care of signing requests with an Hmac key
  """

  @doc """
  adds a "merchantSig" key to the current map which contains the hmac signature contrived from all the key/values
  """
  @spec sign(params :: map) :: map
  def sign(params) when is_map(params) do
    hmac = generate!(params)
    Map.put(params, "merchantSig", hmac)
  end

  @spec generate!(params :: map) :: String.t
  defp generate!(params) do
    hex_hmac_crypto_key = System.get_env("ADYEN_HMAC_KEY") || Application.get_env(:adyen, :hmac_key)
    binary_hmac_crypto_key = Base.decode16!(hex_hmac_crypto_key)
    content_to_hmac = generate_hmac_content_key(params)

    :sha256
    |> :crypto.hmac(binary_hmac_crypto_key, content_to_hmac)
    |> Base.encode64
  end

  @spec generate_hmac_content_key(contents :: map) :: String.t
  defp generate_hmac_content_key(contents) do
    contents
    |> escape_contents
    |> concatenate_contents
  end

  @spec escape_contents(contents :: map) :: map
  defp escape_contents(contents) do
    contents
    |> Enum.into(%{}, fn ({key, value}) -> {key, escape_value(value)} end)
  end

  @spec escape_value(value :: number) :: String.t
  defp escape_value(value) when is_integer(value), do: Integer.to_string(value)

  @spec escape_value(value :: binary) :: String.t
  defp escape_value(value) when is_binary(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace(":", "\\:")
  end

  # If `contents` is:
  #
  #   {foo: "bar", baz: "quux"}
  #
  # Then this function will turn that into:
  #
  #   "baz:foo:quux:bar"
  @spec concatenate_contents(contents :: map) :: String.t
  defp concatenate_contents(contents) do
    sorted_keys = Enum.sort(Map.keys(contents))
    values_for_sorted_keys = Enum.into(sorted_keys, [], fn key -> Map.fetch!(contents, key) end)
    "#{Enum.join(sorted_keys, ":")}:#{Enum.join(values_for_sorted_keys, ":")}"
  end
end