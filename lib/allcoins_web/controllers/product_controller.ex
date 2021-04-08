defmodule AllcoinsWeb.ProductController do
  use AllcoinsWeb, :controller

  def index(conn, _params) do
    trades =
      Allcoins.available_products()
      |> Allcoins.get_last_trades()

    render(conn, "index.html", trades: trades)
  end
end
