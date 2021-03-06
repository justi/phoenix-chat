defmodule Slackir do
  use Application

  defp init_ets() do
    :ets.new(:disappearing_messages_table, [:set, :public, :named_table])
  end

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Slackir.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Slackir.Endpoint, []),
      # Start your own worker by calling: Slackir.Worker.start_link(arg1, arg2, arg3)
      # worker(Slackir.Worker, [arg1, arg2, arg3]),
      worker(Slackir.DeleteMessagesWorker, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Slackir.Supervisor]
    init_ets()
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Slackir.Endpoint.config_change(changed, removed)
    :ok
  end
end