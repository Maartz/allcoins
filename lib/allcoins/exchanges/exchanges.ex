defmodule Allcoins.Exchanges do

  alias Allcoins.{Product, Trade}
  # Exchanges Context
  # Group exchanges functions
  # Public API

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
