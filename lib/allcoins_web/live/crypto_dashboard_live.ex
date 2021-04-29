defmodule AllcoinsWeb.CryptoDashboardLive do

  import AllcoinsWeb.ProductHelpers

  use AllcoinsWeb, :live_view
  alias Allcoins.Product

  def mount(_params, _session, socket) do
    IO.inspect(self(), label: "LIVEVIEW MOUNT")
    socket = assign(socket, trades: %{}, products: [])
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <div class="allcoins-toolbar">
    <div class="title">Allcoins</div>
      <form action="#" phx-submit="add-product">
        <select name="product_id" class="select-product">

        <option selected disabled>Add a Crypto Product</option>

        <%= for {exchange_name, products} <- grouped_products_by_exchange_name() do %>
          <optgroup label="<%= exchange_name %>">
            <%= for product <- products do %>
              <option value="<%= to_string(product) %>">
                  <%= crypto_name(product) %>
                  -
                  <%= fiat_character(product) %>
              </option>
            <% end %>
          </optgroup>
        <% end %>
        </select>
        <input type="submit" value="+" />
      </form>
    </div>
    <div class="product-components">
    <%= for product <- @products, trade = @trades[product] do%>
    <%= live_component @socket, AllcoinsWeb.ProductComponent,
          product: product, trade: trade %>
    <% end %>
    </div>
    """
  end

  def handle_info({:new_trade, trade}, socket) do
    socket = update(socket, :trades, &Map.put(&1, trade.product, trade))

    {:noreply, socket}
  end

  def handle_event("clear", _params, socket) do
    {:noreply, assign(socket, :trades, %{})}
  end

  def handle_event("add-product", %{"product_id" => product_id} = _params, socket) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    product = Product.new(exchange_name, currency_pair)
    socket = maybe_add_product(socket, product)
    {:noreply, socket}
  end

  def handle_event("add-product", _, socket), do: {:noreply, socket}

  def handle_event("filter-products", %{"search" => search}, socket) do
    products =
      Allcoins.available_products()
      |> Enum.filter(fn product ->
        String.downcase(product.exchange_name) =~ String.downcase(search) or
        String.downcase(product.currency_pair) =~ String.downcase(search)
      end)

    {:noreply, assign(socket, :products, products)}
  end

  def add_product(socket, product) do
    Allcoins.subscribe_to_trades(product)

    socket
    |> update(:products, &(&1 ++ [product]))
    |> update(:trades, fn trades ->
      trade = Allcoins.get_last_trade(product)
      Map.put(trades, product, trade)
    end)
  end

  @spec maybe_add_product(Phoenix.LiveView.Socket.t(), Product.t()) :: Phoenix.LiveView.Socket.t()
  defp maybe_add_product(socket, product) do
    if product not in socket.assigns.products do
      socket
      |> add_product(product)
      |> put_flash(
           :info,
           "#{product.exchange_name} - #{product.currency_pair} added successfully"
         )
    else
      put_flash(socket, :error, "The product was already added")
    end
  end

  defp grouped_products_by_exchange_name do
    Allcoins.available_products()
    |> Enum.group_by(& &1.exchange_name)
  end
end