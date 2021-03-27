defmodule Allcoins do
  @moduledoc """
  Allcoins keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defdelegate subscribe_to_trades(product), to: Allcoins.Exchanges, as: :subscribe
  defdelegate unsubscribe_to_trades(product), to: Allcoins.Exchanges, as: :unsubscribe

  defdelegate get_last_trade(product), to: Allcoins.Historical
  defdelegate get_last_trades(products), to: Allcoins.Historical
end
