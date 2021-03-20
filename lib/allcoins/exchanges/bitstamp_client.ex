defmodule Allcoins.Exchanges.BitstampClient do
  @moduledoc """
   BistampClient provides an interface to connect in WS to Coinbase crypto-currency feed.
  To start a connexion, you need to pass the BistampClient module to the Client.start_link function.
  See the Client module documentation for further info.

  The BistampClient.available_currency list all the current supported currency.
  """

  alias Allcoins.{Product, Trade}
  alias Allcoins.Exchanges.Client
  require Client

  Client.defclient(
    exchange_name: "bitstamp",
    host: 'ws.bitstamp.net',
    port: 443,
    currency_pairs: ["btcusd", "ethusd", "ltcusd", "btceur", "etheur", "ltceur"]
  )

  @impl true
  def handle_ws_message(%{"event" => "trade"} = msg, state) do
    _trade = message_to_trade(msg) |> IO.inspect(label: "Bitstamp")
    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  @spec subscription_frames(list()) :: list()
  def subscription_frames(currency_pairs) do
    Enum.map(currency_pairs, &subscription_frame/1)
  end

  defp subscription_frame(currency_pair) do
    #  https://www.bitstamp.net/websocket/v2/
    msg =
      %{
        "event" => "bts:subscribe",
        "data" => %{
          "channel" => "live_trades_#{currency_pair}"
        }
      }
      |> Jason.encode!()

    {:text, msg}
  end

  @spec message_to_trade(map()) :: {:ok, Trade.t()} | {:error, any()}
  def message_to_trade(%{"data" => data, "channel" => "live_trades_" <> currency_pair} = _msg)
      when is_map(data) do
    with :ok <-
           validate_required(
             data,
             ["amount_str", "price_str", "timestamp"]
           ),
         {:ok, traded_at} <- timestamp_to_datetime(data["timestamp"]) do
      Trade.new(
        product: Product.new(exchange_name(), currency_pair),
        price: data["price_str"],
        volume: data["amount_str"],
        traded_at: traded_at
      )
    else
      {:error, _reason} = error -> error
    end
  end

  def message_to_trade(_msg), do: {:error, :invalid_trade_message}

  @spec timestamp_to_datetime(String.t()) :: {:ok, DateTime.t()} | {:error, atom()}
  defp timestamp_to_datetime(timestamp) do
    case Integer.parse(timestamp) do
      {ts, _} -> DateTime.from_unix(ts)
      :error -> {:error, :invalid_timestamp_string}
    end
  end
end
