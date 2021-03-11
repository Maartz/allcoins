defmodule Allcoins.Exchanges.CoinbaseClient do
  @moduledoc """

  """

  use GenServer

  # TODO: handle when the connection is closed
  # Last message: {:gun_down, #PID<0.391.0>, :ws, :closed, [], []}

  # TODO: handle when the host is false/unreachable

  @server_host 'ws-feed.pro.coinbase.com'
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

  @spec handle_ws_message(any, any) :: {:noreply, any}
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
    msg =
      %{
        "type" => "subscribe",
        "product_ids" => currency_pairs,
        "channels" => ["ticker"]
      }
      |> Jason.encode!()

    [{:text, msg}]
  end

  @spec connect(%{:conn => any, optional(any) => any}) :: %{:conn => pid, optional(any) => any}
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
end
