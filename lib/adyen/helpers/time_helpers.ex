defmodule Adyen.Helpers.TimeHelpers do
  @moduledoc """
  This module contains a few time helper functions
  """

  @doc """
  Returns a formatted timestamp which is X minutes into the future. for example : 2017-09-13T11:34:29+00:00
  """
  @spec formatted_minutes_from_now(minutes :: integer) :: String.t
  def formatted_minutes_from_now(minutes) when is_integer(minutes) and minutes > 0 do
    Timex.now
    |> Timex.shift(minutes: minutes)
    |> Timex.format!("%FT%T%:z", :strftime)
  end
end