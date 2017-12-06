defmodule Adyen.Client do
  @moduledoc """
  This module wraps the json api of Adyen using Maxwell
  """

  use Maxwell.Builder, [:get, :post]

  #  middleware Maxwell.Middleware.BaseUrl, (if Application.get_env(:adyen, :mode) == :live, do: "https://live.adyen.com/", else: "https://test.adyen.com/")
  middleware Maxwell.Middleware.BaseUrl, "https://test.adyen.com/"
  middleware Maxwell.Middleware.Headers, %{"content-type" => "application/json; charset=utf-8"}
  middleware Maxwell.Middleware.Opts, connect_timeout: 3000
  middleware Maxwell.Middleware.Json
  #  middleware Maxwell.Middleware.Logger

  adapter Maxwell.Adapter.Hackney

  @doc"""
  This call will fabricate a redirect url to adyen to which you can send the client to confirm payment.
  """
  @spec request_capture(options :: %Adyen.Options{}) :: {:ok, String.t}
  def request_capture(%Adyen.Options{issuer_id: issuer_id, method: "ideal"} = options) when not is_nil(issuer_id) do
    {:ok, "https://test.adyen.com/hpp/skipDetails.shtml?" <> Adyen.Options.to_query_string(options)}
  end
  def request_capture(%Adyen.Options{} = options) do
    {:ok, "https://test.adyen.com/hpp/pay.shtml?" <> Adyen.Options.to_query_string(options)}
  end

  def request_sepa_capture(%Adyen.Options.SepaOptions{} = sepa_options) do
    json = Adyen.Options.SepaOptions.to_post_map(sepa_options)
    "https://pal-test.adyen.com/pal/servlet/Payment/v30/authorise"
    |> new
    |> put_req_body(json)
    |> put_req_header("Content-Type", "application/json")
    |> put_req_header("Authorization", "Basic #{basic_auth(sepa_options)}")
    |> post
    |> process_response
    |> Adyen.CaptureRequestResponse.parse(sepa_options)
  end

  def capture_payment(%Adyen.CaptureRequestResponse{capture_info: options}) do
    "https://pal-test.adyen.com/pal/servlet/Payment/v30/capture"
    |> new
    |> put_req_body(
         %{
           merchantAccount: options.account,
           modificationAmount: options.amount,
           originalReference: options.original_reference
         }
       )
    |> put_req_header("Authorization", "Basic #{basic_auth(options)}")
    |> put_req_header("Content-Type", "application/json")
    |> post
    |> process_response
    |> parse_sepa_capture_response
  end

  @doc """
  Gets a list for ideal banks that are supported for the current adyen account.
  Please use the Adyen.get_banks/0 function which will use cached data. This function here should only be used by
  the Adyen.BanksCache to warmup its cache.
  """
  @spec get_banks :: {:ok, map} | {:error, any}
  def get_banks do
    {:ok, options} = Adyen.Options.credentials(amount_in_cents: 100)
    query_string = Adyen.Options.to_query_string(options)
    "https://test.adyen.com/hpp/directory/v2.shtml?#{query_string}"
    |> new
    |> get
    |> process_response
    |> parse_issuers
  end
  # FIXME there is a bug in MAXWELL apparently that when the path contains an extention, it does not use the base url
  # for example when using "/hpp/directory.shtml" it because http:///hpp/directory.shtml...
  #    params = Adyen.Options.to_post_map(options)
  #     "https://test.adyen.com/hpp/directory.json"
  #        |> new
  #        |> put_req_body(params)
  #        |> post
  #        |> process_response

  @spec process_response({:ok, response :: %Maxwell.Conn{}}) :: {:ok, map} | {:error, any}
  defp process_response({:ok, %Maxwell.Conn{status: 401}}), do: {:error, :invalid_api_token_or_service_id}
  defp process_response({:ok, %Maxwell.Conn{status: 200, resp_body: body}}), do: {:ok, body}
  defp process_response({:ok, %Maxwell.Conn{status: _, resp_body: body}}), do: {:error, body}
  defp process_response({:error, _} = error), do: error

  @spec parse_issuers({:ok, data :: map} | any) :: {:ok, map} | any
  defp parse_issuers({:ok, data}) when is_binary(data) do
    case Regex.named_captures(~r/Error:\s(?<error>.*)/, data) do
      %{"error" => message} -> {:error, clean_html_string(message)}
      _ -> {:error, data}
    end
  end
  defp parse_issuers({:ok, data}) when is_map(data) do

    case get_ideal_entry(data) do
      {:ok, entry} ->
        issuers = entry
                  |> Map.get("issuers")
                  |> Enum.map(&normalize_issuer_entry/1)

        {:ok, issuers}
      error -> error
    end
  end
  defp parse_issuers(error), do: error

  defp normalize_issuer_entry(%{"issuerId" => issuer_id, "name" => name}) do
    %{issuer_id: String.to_integer(issuer_id), name: name}
  end

  defp basic_auth(sepa_options) do
    Base.encode64("#{sepa_options.basic_auth_username}:#{sepa_options.basic_auth_password}")
  end

  defp clean_html_string(string) do
    string
    |> String.replace("&lt;", "", global: true)
    |> String.replace("&gt;", "", global: true)
    |> String.replace("<br />", "", global: true)
    |> String.replace("br /", " ", global: true)
  end

  defp get_ideal_entry(data) do
    ideal = data
            |> Map.get("paymentMethods")
            |> Enum.find(fn entry -> entry["brandCode"] == "ideal" end)
    case ideal do
      nil -> {:error, :ideal_entry_not_found}
      entry -> {:ok, entry}
    end
  end

  def parse_sepa_capture_response({:ok, %{"pspReference" => reference, "response" => "[capture-received]"}}),
      do: {:ok, String.to_integer(reference)}
  def parse_sepa_capture_response({_, data}), do: {:error, data}
end
