defmodule AllcoinsWeb.ProductHelpers do

  @doc """
  Returns a human-readable timestamp with the following format: `Jan 27, 2021 16:35:08`

  ## Examples

    iex> AllcoinsWeb.ProductHelpers.human_datetime(~U[2021-04-29T08:45:39Z])
    "Apr 29, 2021 08:45:39"
  """

  def human_datetime(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y %H:%M:%S")
  end

  @doc ~S"""
  Returns the cryptocurrency symbol.

  ## Examples
    iex> alias Allcoins.Product
    iex> AllcoinsWeb.ProductHelpers.crypto_symbol(Product.new("coinbase", "BTC-USD"))
    "btc"
    iex> AllcoinsWeb.ProductHelpers.crypto_symbol(Product.new("bitstamp", "etheur"))
    "eth"
  """
  def crypto_symbol(product), do: crypto_and_fiat_symbols(product).crypto_symbol


  @doc ~S"""
  Returns the fiat currency symbol.

  ## Examples

    iex> alias Allcoins.Product
    iex> AllcoinsWeb.ProductHelpers.fiat_symbol(Product.new("coinbase", "BTC-USD"))
    "usd"
    iex> AllcoinsWeb.ProductHelpers.fiat_symbol(Product.new("bitstamp", "etheur"))
    "eur"
  """
  def fiat_symbol(product), do: crypto_and_fiat_symbols(product).fiat_symbol

  def fiat_symbols do
    ["eur", "usd"]
  end

  @doc ~S"""
  Returns the fiat character for a given product.

  ## Examples

    iex> alias Allcoins.Product
    iex> AllcoinsWeb.ProductHelpers.fiat_character(Product.new("coinbase", "BTC-USD"))
    "$"
    iex> AllcoinsWeb.ProductHelpers.fiat_character(Product.new("bitstamp", "etheur"))
    "€"

  """

  def fiat_character(product) do
    case crypto_and_fiat_symbols(product) do
      %{fiat_symbol: "usd"} -> "$"
      %{fiat_symbol: "eur"} -> "€"
    end
  end

  @doc ~S"""
  Provides the correct cryptocurrency symbol for a given Product.
  """
  def crypto_icon(conn, product) do
    crypto_symbol = crypto_symbol(product)
    relative_path = Path.join("/images/cryptos", "#{crypto_symbol}.svg")
    PoeticoinsWeb.Router.Helpers.static_path(conn, relative_path)
  end

  @doc ~S"""
  Returns a map with the cryptocurrency and the fiat symbol.

  ## Examples

    iex> alias Allcoins.Product
    iex> AllcoinsWeb.ProductHelpers.crypto_and_fiat_symbols(Product.new("coinbase", "BTC-USD"))
    %{crypto_symbol: "btc", fiat_symbol: "usd"}
    iex> AllcoinsWeb.ProductHelpers.crypto_and_fiat_symbols(Product.new("bitstamp", "btcusd"))
    %{crypto_symbol: "btc", fiat_symbol: "usd"}
  """
  def crypto_and_fiat_symbols(%{exchange_name: "coinbase"} = product) do
    [crypto_symbol, fiat_symbol] =
      product.currency_pair
      |> String.split("-")
      |> Enum.map(&String.downcase/1)

    %{crypto_symbol: crypto_symbol, fiat_symbol: fiat_symbol}
  end

  def crypto_and_fiat_symbols(%{exchange_name: "bitstamp"} = product) do
    crypto_symbol = String.slice(product.currency_pair, 0..2)
    fiat_symbol = String.slice(product.currency_pair, 3..6)
    %{crypto_symbol: crypto_symbol, fiat_symbol: fiat_symbol}
  end

end
