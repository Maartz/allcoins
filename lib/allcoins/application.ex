defmodule Allcoins.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AllcoinsWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Allcoins.PubSub},
      {Allcoins.Historical, name: Allcoins.Historical},
      {Allcoins.Exchanges.Supervisor, name: Allcoins.Exchanges.Supervisor},
      # Start the Endpoint (http/https)
      AllcoinsWeb.Endpoint
      # Start a worker by calling: Allcoins.Worker.start_link(arg)
      # {Allcoins.Worker, rg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Allcoins.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AllcoinsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
