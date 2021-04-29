defmodule AllcoinsWeb.ProductComponent do
  use AllcoinsWeb, :live_component
  import AllcoinsWeb.ProductHelpers

  def mount(socket) do
    IO.inspect(self(), label: "MOUNT")
    {:ok, socket}
  end

  def update(assigns, socket) do
    IO.inspect(self(), label: "UPDATE")
    socket = assign(socket, assigns)
    {:ok, socket}
  end

  def render(assigns) do
    IO.inspect(self(), label: "RENDER")
    ~L"""
    <div class="product-component">
      <div class="currency-container">
        <img class="icon" src="<%= crypto_icon(@socket, @product) %>" />
        <div class="crypto-name">
          <%= crypto_name(@product) %>
        </div>
      </div>

      <div class="price-container">
        <ul class="fiat-symbols">
          <%= for fiat <- fiat_symbols() do %>
            <li class="
            <%= if fiat_symbol(@product) == fiat, do: "active" %>
              "><%= fiat %></li>
          <% end %>
      </ul>

        <div class="price">
          <%= @trade.price %>
          <%= fiat_character(@product) %>
        </div>
      </div>

      <div class="exchange-name">
        <%= @product.exchange_name %>
      </div>

      <div class="trade-time">
        <%= human_datetime(@trade.traded_at) %>
      </div>
    </div>
    """
  end
end