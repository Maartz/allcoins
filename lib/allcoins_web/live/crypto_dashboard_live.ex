defmodule AllcoinsWeb.CryptoDashboardLive do
  use AllcoinsWeb, :live_view
  alias Allcoins.Product
  import AllcoinsWeb.ProductHelpers

  def mount(_params, _session, socket) do
    socket = assign(socket, trades: %{}, products: [], timezone: get_timezone_from_conn(socket))
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
    <%= for product <- @products do%>
      <%= live_component @socket, AllcoinsWeb.ProductComponent, id: product, timezone: @timezone %>
    <% end %>
    </div>
    """
  end

  def handle_info({:new_trade, trade}, socket) do
    send_update(
      AllcoinsWeb.ProductComponent,
      id: trade.product,
      trade: trade
    )

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

  def handle_event("remove-product", %{"product-id" => product_id} = _params, socket) do
    product = product_from_string(product_id)
    Allcoins.unsubscribe_to_trades(product) # TODO: unsubscribe_to_trades must be renamed to unsubscribe_from_trades
    socket = update(socket, :products, &List.delete(&1, product))
    {:noreply, socket}
  end

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

  defp product_from_string(product_id) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    Product.new(exchange_name, currency_pair)
  end

  defp get_timezone_from_conn(socket) do
    case get_connect_params(socket) do
      %{"timezone" => tz} when not is_nil(tz) -> tz
      _ -> "UTC"
    end
  end
end
