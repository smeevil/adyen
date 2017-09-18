defmodule Adyen.BanksCache do
  @moduledoc """
  This will start a GenServer that will keep a hot cache for the available Banks that the used account at adyen provides.
  Because of this cache we do not have to live query the adyen servers each time.
  """
  use GenServer

  @spec start_link :: {:ok, pid}
  def start_link() do
    GenServer.start_link(__MODULE__, %{}, [name: __MODULE__])
  end

  @spec init(options :: map) :: {:ok, map}
  def init(_options) do
    {:ok, _ref} = :timer.apply_after(100, __MODULE__, :warmup_cache, [])
    {:ok, %{hot_cache: false}}
  end

  @spec warmup_cache :: :ok | {:error, String.t}
  def warmup_cache do
    case GenServer.call(__MODULE__, {:warmup_cache}) do
      :ok -> :ok
      {:error, message} -> IO.puts "ERROR: #{inspect message}"
    end
  end

  def handle_call({:get_banks}, _from, state) do
    if state.hot_cache do
      {:reply, {:ok, state.cache}, state}
    else
      case get_banks() do
        {:ok, data} -> {:reply, data, %{hot_cache: true, cache: data}}
        error -> {:reply, error, state}
      end
    end
  end

  def handle_call({:get_issuer_ids}, _from, state) do
    if state.hot_cache do
      {:reply, {:ok, get_issuer_ids(state.cache)}, state}
    else
      case get_banks() do
        {:ok, data} -> {:reply, get_issuer_ids(data), %{hot_cache: true, cache: data}}
        error -> {:reply, error, state}
      end
    end
  end

  def handle_call({:warmup_cache}, _from, state) do
    case get_banks() do
      {:ok, data} -> {:reply, :ok, %{hot_cache: true, cache: data}}
      error -> {:reply, error, state}
    end
  end

  @spec get_banks :: {:ok, map} | {:error, any()}
  defp get_banks, do: Adyen.Client.get_banks

  defp get_issuer_ids(data) do
    Enum.map(data, &(&1.issuer_id))
  end
end