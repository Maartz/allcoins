defmodule AllcoinsWeb.CryptoDashboardLive do
  use AllcoinsWeb, :live_view
  alias Allcoins.Product

  @impl true
  def mount(_params, _session, socket) do
    product = Product.new("coinbase", "BTC-EUR")
    trade = Allcoins.get_last_trade(product)

    if socket.connected? do
      Allcoins.subscribe_to_trades(product)
    end

    socket = assign(socket, :trade, trade)
    {:ok, socket}
  end

  @impl true
  def handle_info({:new_trade, trade}, socket) do
    socket = assign(socket, :trade, trade)
    {:noreply, socket}
  end

  @impl true
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~L"""
    <h2>
      <%= @trade.product.exchange_name %> -
      <%= @trade.product.currency_pair %>
    </h2>
    <p>
      <%= @trade.traded_at %> -
      <%= @trade.price %> -
      <%= @trade.volume %>
    </p>
    """
  end
end
