defmodule Gitsome.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      GitsomeWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Gitsome.PubSub},
      # Start the Endpoint (http/https)
      GitsomeWeb.Endpoint,
      # Start a worker by calling: Gitsome.Worker.start_link(arg)
      # {Gitsome.Worker, arg}
      
      # GITHUB ETS CACHE
      {Gitsome.GithubEtsCacheSupervisor, []},
      # GITHUB TASKER (CACHE CHECKER AND PARSER)
      {Gitsome.GithubTaskerSupervisor, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gitsome.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GitsomeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
