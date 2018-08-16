# See https://github.com/alfredherr/registry_sample
defmodule AccountSupervisor do
  use Supervisor
  require Logger
  @account_registry_name :accounts_registry

  def start_link, do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    children = [
      worker(Account, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def find_or_create_process(account_id) do
    # IO.puts "Finding #{account_id}"
    if account_process_exists?(account_id) do
      {:ok, account_id}
    else
      account_id |> create_account_process
    end
  end

  def account_process_exists?(account_id) do
    case Registry.lookup(@account_registry_name, account_id) do
      [] -> false
      _ -> true
    end
  end

  def create_account_process(account_id) do
    # IO.puts "Creating #{account_id}"
    case Supervisor.start_child(__MODULE__, [account_id]) do
      {:ok, _pid} -> {:ok, account_id}
      {:error, {:already_started, _pid}} -> {:error, :process_already_exists}
      other -> {:error, other}
    end
  end

  def account_process_count, do: Supervisor.which_children(__MODULE__) |> length

  def account_numbers do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, account_proc_pid, _, _} ->
      Registry.keys(@account_registry_name, account_proc_pid) |> List.first()
    end)
    |> Enum.sort()
  end
end
