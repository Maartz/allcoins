defmodule Allcoins.Exchanges.CoinbaseClient do
  # TODO: handle when the connection is closed
  # Last message: {:gun_down, #PID<0.391.0>, :ws, :closed, [], []}

  # TODO: handle when the host is false/unreachable

  @moduledoc """
  CoinbaseClient provides an interface to connect in WS to Coinbase crypto-currency feed.
  To start a connexion, you need to pass the CoinbaseClient module to the Client.start_link function.
  See the Client module documentation for further info.

  The CoinbaseClient.available_currency list all the current supported currency.
  """

  alias Allcoins.{Product, Trade, Exchanges}
  alias Allcoins.Exchanges.{Client}
  require Client

  Client.defclient(
    exchange_name: "coinbase",
    host: 'ws-feed.pro.coinbase.com',
    port: 443,
    currency_pairs: ["BTC-USD", "BTC-EUR", "ETH-EUR", "ETH-USD", "LTC-EUR", "LTC-USD"]
  )

  @impl true
  def handle_ws_message(%{"type" => "ticker"} = msg, state) do
    {:ok, trade} = message_to_trade(msg)
    Exchanges.broadcast(trade)
    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  @impl true
  def subscription_frames(currency_pairs) do
    # https://docs.pro.coinbase.com/#subscribe
    # https://docs.pro.coinbase.com/#the-ticker-channel
    msg =
      %{
        "type" => "subscribe",
        "product_ids" => currency_pairs,
        "channels" => ["ticker"]
      }
      |> Jason.encode!()

    [{:text, msg}]
  end

  @doc """
  Map a message coming from Coinbase to valid Trade struct.
  Otherwise, it returns an error.
  """
  @spec message_to_trade(map()) :: {:ok, Trade.t()} | {:error, any()}
  def message_to_trade(msg) do
    with :ok <-
           validate_required(
             msg,
             ["price", "product_id", "last_size", "time"]
           ),
         {:ok, traded_at, _} = DateTime.from_iso8601(msg["time"]) do
      currency_pair = msg["product_id"]
      {:ok,
        Trade.new(
          product: Product.new(exchange_name(), currency_pair),
          price: msg["price"],
          volume: msg["last_size"],
          traded_at: traded_at
        )
      }
    else
      {:error, _reason} = error -> error
    end
  end
end
