defmodule AllcoinsWeb.CryptoDashboardLive do
  use AllcoinsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    products = Allcoins.available_products()

    trades =
      products
      |> Allcoins.get_last_trades()
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&{&1.product, &1})
      |> Enum.into(%{})

    if socket.connected? do
      Enum.each(products, &Allcoins.subscribe_to_trades(&1))
    end

    socket = assign(socket, trades: trades, products: products)
    {:ok, socket}
  end

  @impl true
  def handle_info({:new_trade, trade}, socket) do
    socket = update(socket, :trades, fn trades ->
      Map.put(trades, trade.product, trade)
    end)
    {:noreply, socket}
  end

  @impl true
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~L"""
    <table>
       <thead>
         <th>Traded at</th>
         <th>Exchange</th>
         <th>Currency</th>
         <th>Price</th>
         <th>Volume</th>
       </thead>
       <tbody>
       <%= for product <- @products, trade = @trades[product], not is_nil(trade) do%>
        <tr>
          <td><%= trade.traded_at %></td>
          <td><%= trade.product.exchange_name %></td>
          <td><%= trade.product.currency_pair %></td>
          <td><%= trade.price %></td>
          <td><%= trade.volume %></td>
        </tr>
      <% end %>
      </tbody>
    </table>
    """
  end
end
