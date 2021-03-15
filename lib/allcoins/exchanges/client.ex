defmodule Allcoins.Exchanges.Client do
  use GenServer

  @type client :: %__MODULE__{
    module: module(),
    conn: pid(),
    conn_ref: reference(),
    currency_pairs: [String.t()]
  }

  @callback exchange_name() :: String.t()
  @callback server_host() :: list()
  @callback server_port() :: integer()
  @callback subscription_frames([String.t()]) :: [{:text, String.t()}]
  @callback handle_ws_message(map(), module()) :: any()

  defstruct [:module, :conn, :conn_ref, :currency_pairs]

  def start_link(module, currency_pairs, options \\ []) do
    GenServer.start_link(__MODULE__, {module, currency_pairs}, options)
  end

  @spec init({module(), [String.t()]}) :: {:ok, client, {:continue, :connect}}
  def init({module, currency_pairs}) do
    # Initialize the state of the process
    client = %__MODULE__{
      module: module,
      currency_pairs: currency_pairs
    }

    {:ok, client, {:continue, :connect}}
  end

  @spec handle_continue(:connect, %{:conn => any, optional(any) => any}) ::
          {:noreply, %{:conn => pid, optional(any) => any}}
  def handle_continue(:connect, client) do
    # Called async because of {:continue, :connect} in the init
    {:noreply, connect(client)}
  end

  @spec connect(%{:conn => any, optional(any) => any}) :: %{:conn => pid, optional(any) => any}
  def connect(client) do
    host = server_host(client.module)
    port = server_port(client.module)
    {:ok, conn} = :gun.open(host, port, %{protocols: [:http]})
    conn_ref = Process.monitor(conn)
    %{client | conn: conn, conn_ref: conn_ref}
  end

  # Pattern matching on gun return tuples
  # https://ninenines.eu/docs/en/gun/2.0/manual/gun/
  def handle_info({:gun_up, conn, :http}, %{conn: conn} = client) do
    :gun.ws_upgrade(conn, "/")
    {:noreply, client}
  end

  def handle_info({:gun_upgrade, conn, _ref, ["websocket"], _headers}, %{conn: conn} = client) do
    subscribe(client)
    {:noreply, client}
  end

  def handle_info({:gun_ws, conn, _ref, {:text, msg} = _frame}, %{conn: conn} = client) do
    apply(client.module, :handle_ws_message, [Jason.decode!(msg), client])
  end

  @spec validate_required(map(), [String.t()]) :: :ok | {:error, {String.t(), :required}}
  def validate_required(msg, keys) do
    required_key = Enum.find(keys, &is_nil(msg[&1]))

    if is_nil(required_key), do: :ok,
    else: {:error, {required_key, :required}}
  end

  defp subscribe(client) do
    # subscription frames
    apply(client.module, :subscription_frames, [client.currency_pairs])
    # send subscription frames to coinbase
    |> Enum.each(&:gun.ws_send(client.conn, &1))
  end

  defp server_host(module), do: apply(module, :server_host, [])
  defp server_port(module), do: apply(module, :server_port, [])
end
