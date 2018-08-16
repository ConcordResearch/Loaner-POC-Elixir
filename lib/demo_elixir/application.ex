defmodule DemoElixir.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: true

    # List all child processes to be supervised
    children = [
      %{id: Datastore, start: {Datastore, :start_link, [[name: :db, file: "db/accounts.dets"]]}},
      %{
        id: Test_Datastore,
        start: {Datastore, :start_link, [[name: :test_db, file: "db/accounts_test.dets"]]}
      },
      supervisor(Registry, [:unique, :accounts_registry]),
      supervisor(AccountSupervisor, [])
    ]

    opts = [strategy: :one_for_one, name: DemoElixir.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
