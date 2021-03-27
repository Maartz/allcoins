defmodule Allcoins.Exchanges do

  alias Allcoins.{Product, Trade}
  # Exchanges Context
  # Group exchanges functions
  # Public API

  @clients [
    Allcoins.Exchanges.CoinbaseClient,
    Allcoins.Exchanges.BitstampClient
  ]

  # Calculated at compile time
  # It's calculated once
  @available_products (for client <- @clients, pair <- client.available_currency_pairs() do
    Product.new(client.exchange_name(), pair)
  end)

  @spec clients :: [module()]
  def clients, do: @clients

  @spec available_products() :: [Product.t()]
  def available_products, do: @available_products

  @spec subscribe(Product.t()) :: :ok | {:error, term}
  def subscribe(product) do
    Phoenix.PubSub.subscribe(Allcoins.PubSub, topic(product))
  end

  @spec unsubscribe(Product.t()) :: :ok | {:error, term}
  def unsubscribe(product) do
   Phoenix.PubSub.unsubscribe(Allcoins.PubSub, topic(product))
  end

  @spec broadcast(Trade.t()) :: :ok | {:error, term}
  def broadcast(trade) do
    Phoenix.PubSub.broadcast(Allcoins.PubSub, topic(trade.product), {:new_trade, trade})
  end

  @spec topic(Product.t()) :: String.t()
  defp topic(product) do
    to_string(product)
  end
end
