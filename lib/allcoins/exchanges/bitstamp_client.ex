defmodule Allcoins.Exchanges.BitstampClient do
@moduledoc """

  """

  alias Allcoins.{Product, Trade}

  use GenServer
  @exchange_name "bitstamp"

  # TODO: handle when the connection is closed
  # Last message: {:gun_down, #PID<0.391.0>, :ws, :closed, [], []}

  # TODO: handle when the host is false/unreachable
  # TODO: find a way to avoid code repetition in exchanges modules

  @server_host 'ws.bitstamp.net'
  @server_port 443

  @spec start_link(any, [
          {:debug, [:log | :statistics | :trace | {any, any}]}
          | {:hibernate_after, :infinity | non_neg_integer}
          | {:name, atom | {:global, any} | {:via, atom, any}}
          | {:spawn_opt,
             :link
             | :monitor
             | {:fullsweep_after, non_neg_integer}
             | {:min_bin_vheap_size, non_neg_integer}
             | {:min_heap_size, non_neg_integer}
             | {:priority, :high | :low | :normal}}
          | {:timeout, :infinity | non_neg_integer}
        ]) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(currency_pairs, options \\ []) do
    GenServer.start_link(__MODULE__, currency_pairs, options)
  end

  @spec init(any) :: {:ok, %{conn: nil, currency_pairs: any}, {:continue, :connect}}
  def init(currency_pairs) do
    # Initialize the state of the process
    state = %{
      currency_pairs: currency_pairs,
      conn: nil
    }

    {:ok, state, {:continue, :connect}}
  end

  @spec handle_continue(:connect, %{:conn => any, optional(any) => any}) ::
          {:noreply, %{:conn => pid, optional(any) => any}}
  def handle_continue(:connect, state) do
    # Called async because of {:continue, :connect} in the init
    {:noreply, connect(state)}
  end

  # Pattern matching on gun return tuples
  # https://ninenines.eu/docs/en/gun/2.0/manual/gun/
  def handle_info({:gun_up, conn, :http}, %{conn: conn} = state) do
    :gun.ws_upgrade(conn, "/")
    {:noreply, state}
  end

  def handle_info({:gun_upgrade, conn, _ref, ["websocket"], _headers}, %{conn: conn} = state) do
    subscribe(state)
    {:noreply, state}
  end

  def handle_info({:gun_ws, conn, _ref, {:text, msg} = _frame}, %{conn: conn} = state) do
    handle_ws_message(Jason.decode!(msg), state)
  end

  # @spec handle_ws_message(any, any) :: {:noreply, any}
  # def handle_ws_message(%{"type" => "ticker"} = msg, state) do
  #   trade = message_to_trade(msg) |> IO.inspect(label: "trade")
  #   {:noreply, state}
  # end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
    """
    unhandled message: %{
      "channel" => "live_trades_btceur",
      "data" => %{
        "amount" => 0.05772371,
        "amount_str" => "0.05772371",
        "buy_order_id" => 1338955183640576,
        "id" => 157353479,
        "microtimestamp" => "1615728330038000",
        "price" => 49794.61,
        "price_str" => "49794.61",
        "sell_order_id" => 1338955180769280,
        "timestamp" => "1615728330",
        "type" => 0
      },
      "event" => "trade"
    }
    """
  end

  @spec subscription_frames(list()) :: list()
  def subscription_frames(currency_pairs) do
    Enum.map(currency_pairs, &subscription_frame/1)
  end

  defp subscription_frame(currency_pair) do
    #  https://www.bitstamp.net/websocket/v2/
    msg = %{
      "event" => "bts:subscribe",
      "data" => %{
        "channel" => "live_trades_#{currency_pair}"
      }
    } |> Jason.encode!()
    {:text, msg}
  end

  def connect(state) do
    {:ok, conn} = :gun.open(@server_host, @server_port, %{protocols: [:http]})
    %{state | conn: conn}
  end

  defp subscribe(state) do
    # subscription frames
    subscription_frames(state.currency_pairs)
    # send subscription frames to coinbase
    |> Enum.each(&:gun.ws_send(state.conn, &1))
  end

  # @spec message_to_trade(map()) :: {:ok, Trade.t()} | {:error, any()}
  # def message_to_trade(msg) do
  #   with :ok <- validate_required(msg,
  #     ["price", "product", "traded_at", "time"]),
  #     {:ok, traded_at, _} = DateTime.from_iso8601(msg["time"])
  #   do
  #   currency_pair = msg["product_id"]
  #   Trade.new(
  #     product: Product.new(@exchange_name, currency_pair),
  #     price: msg["price"],
  #     volume: msg["last_size"],
  #     traded_at: traded_at
  #   )
  #   else
  #     {:error, _reason} = error -> error
  #   end
  # end

  # @spec validate_required(map(), [String.t()]) :: :ok | {:error, {String.t(), :required}}
  # def validate_required(msg, keys) do
  #   required_key = Enum.find(keys, &is_nil(msg[&1]))

  #   cond do
  #     is_nil(required_key) == true -> :ok
  #     true -> {:error, {required_key, :required}}
  #   end
  # end
end
