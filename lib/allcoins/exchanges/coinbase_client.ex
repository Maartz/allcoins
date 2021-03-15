defmodule Allcoins.Exchanges.CoinbaseClient do
  # TODO: handle when the connection is closed
  # Last message: {:gun_down, #PID<0.391.0>, :ws, :closed, [], []}

  # TODO: handle when the host is false/unreachable

  @moduledoc """

  """

  alias Allcoins.{Product, Trade}
  alias Allcoins.Exchanges.Client
  import Client, only: [validate_required: 2]

  @behaviour Client
  @impl true
  @spec exchange_name :: <<_::64>>
  def exchange_name, do: "coinbase"
  @impl true
  def server_host, do: 'ws-feed.pro.coinbase.com'
  @impl true
  def server_port, do: 443


  @impl true
  def handle_ws_message(%{"type" => "ticker"} = msg, state) do
    _trade = message_to_trade(msg) |> IO.inspect(label: "Coinbase")
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

  @spec message_to_trade(map()) :: {:ok, Trade.t()} | {:error, any()}
  def message_to_trade(msg) do
    with :ok <-
           validate_required(
             msg,
             ["price", "product_id", "last_size", "time"]
           ),
         {:ok, traded_at, _} = DateTime.from_iso8601(msg["time"]) do
      currency_pair = msg["product_id"]

      Trade.new(
        product: Product.new(exchange_name(), currency_pair),
        price: msg["price"],
        volume: msg["last_size"],
        traded_at: traded_at
      )
    else
      {:error, _reason} = error -> error
    end
  end

end
