defmodule Allcoins.Exchanges.CoinbaseClient do
  @moduledoc """

  """

  use GenServer

  # TODO: handle when the connection is closed
  # Last message: {:gun_down, #PID<0.391.0>, :ws, :closed, [], []}

  # TODO: handle when the host is false/unreachable

  @server_host 'ws-feed.pro.coinbase.com'
  @server_port 443

  def start_link(currency_pairs, options \\ []) do
    GenServer.start_link(__MODULE__, currency_pairs, options)
  end

  def init(currency_pairs) do
    # Initialize the state of the process
    state = %{
      currency_pairs: currency_pairs,
      conn: nil
    }
    {:ok, state, {:continue, :connect}}
  end

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

  def handle_ws_message(%{"type" => "ticker"} = msg, state) do
    IO.inspect(msg, label: "ticker")
    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  def subscription_frames(currency_pairs) do
    # https://docs.pro.coinbase.com/#subscribe
    # https://docs.pro.coinbase.com/#the-ticker-channel
    msg = %{
      "type" => "subscribe",
      "product_ids" => currency_pairs,
      "channels" => ["ticker"]
    } |> Jason.encode!()
    [{:text, msg}]
  end

  def connect(state) do
    {:ok, conn} = :gun.open(@server_host, @server_port, %{protocols: [:http]})
    %{state | conn: conn}
  end

  defp subscribe(state) do
    # subscription frames
    subscription_frames(state.currency_pairs)
    # send subscription frames to coinbase
    |> Enum.each(fn frame -> :gun.ws_send(state.conn, frame) end)
    # |> Enum.each(&:gun.ws_send(state.conn, &1))
  end
end
