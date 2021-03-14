defmodule Allcoins.Trade do
  alias Allcoins.Product

  @type trade :: %__MODULE__{
          product: Product.t(),
          traded_at: DateTime.t(),
          price: String.t(),
          volume: String.t()
        }
  defstruct [:product, :traded_at, :price, :volume]

  @doc """
  Return a new Allcoins.Product struct.
  Use keyword list because it got a lot of values to initialize.
  ### Example
    t = Trade.new product: Product.new("coinbase", "BTC-USD"), traded_at: DateTime.utc_now(), price: "10000", volume: "0.1"

    t.price == "10000"
    t.product.currency_pair == "BTC-USD"
  """
  @spec new(Keyword.t()) :: trade
  def new(fields) do
    # Kernel.struct! emulates the compile time behaviour of structs
    struct!(__MODULE__, fields)
  end
end

"""
trade: %{
  "best_ask" => "56970.00", # not needed
  "best_bid" => "56969.99", # not needed
  "high_24h" => "57700", # not needed
  "last_size" => "0.00041077", # not needed
  "low_24h" => "54283", # not needed
  "open_24h" => "56290.83", # not needed
  "price" => "56970",
  "product_id" => "BTC-USD",
  "sequence" => 22596995462, # not needed
  "side" => "buy", # not needed
  "time" => "2021-03-11T20:17:20.890348Z",
  "trade_id" => 143700951, # not needed
  "type" => "ticker", # not needed
  "volume_24h" => "23666.18570983",
  "volume_30d" => "732753.51225245" # not needed
}
"""
