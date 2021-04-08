defmodule Allcoins.Exchanges.Supervisor do
  use Supervisor
  alias Allcoins.Exchanges

  def start_link(opts) do
    {clients, opts} = Keyword.pop(opts, :clients, Exchanges.clients)
    Supervisor.start_link(__MODULE__, clients, opts)
  end

  def init(clients) do
    Supervisor.init(clients, strategy: :one_for_one)
  end
end
