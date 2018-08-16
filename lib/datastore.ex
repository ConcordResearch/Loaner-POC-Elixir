defmodule Datastore do
  use GenServer
  require Logger

  ## 2 hours
  @dbs_backup_cycle 2 * 60 * 60 * 1000

  ##########################################################
  # Start Up Handler
  ##########################################################

  def start_link(name: name, file: file) do
    {:ok, pid} = GenServer.start_link(__MODULE__, file, name: name)
    GenServer.call(pid, {:create_table, file})
    {:ok, pid}
  end

  def init(file) do
    # In 2 hours
    Process.send_after(self(), {:work, file}, @dbs_backup_cycle)

    {:ok, file}
  end

  ##########################################################
  # Client API
  ##########################################################

  def get(pid, %AccountModel{} = a) do
    GenServer.call(pid, {:get, :account, a.account_number})
  end

  def get(pid, %PortfolioModel{} = p) do
    GenServer.call(pid, {:get, :portfolio, p.portfolio_number})
  end

  def get(pid, %AccountModel{} = a, timeout) do
    GenServer.call(pid, {:get, :account, a.account_number}, timeout)
  end

  def get(pid, %PortfolioModel{} = p, timeout) do
    GenServer.call(pid, {:get, :portfolio, p.portfolio_number}, timeout)
  end

  def put(pid, %AccountModel{} = a) do
    GenServer.call(pid, {:put, :account, a})
  end

  def put(pid, %PortfolioModel{} = p) do
    GenServer.call(pid, {:put, :portfolio, p})
  end

  def close(pid) do
    GenServer.call(pid, {:close})
  end

  def backup_store(pid) do
    GenServer.cast(pid, {:backup})
  end

  ##########################################################
  # Callbacks
  ##########################################################

  def handle_info({:work, file}) do
    # Do the work you desire here
    do_close_db(file)
    do_backup_db(file)
    do_reopen_db(file)
    # Start the timer again - 2 hours
    Process.send_after(self(), {:work, file}, @dbs_backup_cycle)
    {:noreply, file}
  end

  def handle_call({:create_table, file}, _from, file) do
    result = do_create_table(file, type: :set)

    {:reply, result, file}
  end

  def handle_call({:close}, _from, file) do
    response = do_close_db(file)

    {:reply, response, file}
  end

  def handle_call({:get, :account, account_number}, _from, file) do
    response = do_handle_call_get(file, account_number)

    {:reply, response, file}
  end

  def handle_call({:get, :portfolio, portfolio_number}, _from, file) do
    response = do_handle_call_get(file, portfolio_number)

    {:reply, response, file}
  end

  def handle_call({:put, :account, account}, _, file) do
    result = do_handle_call_put(file, {account.account_number, account})

    {:reply, result, file}
  end

  def handle_call({:put, :portfolio, portfolio}, _, file) do
    result = do_handle_call_put(file, {portfolio.portfolio_number, portfolio})

    {:reply, result, file}
  end

  def handle_cast({:backup, file}) do
    do_close_db(file)
    do_backup_db(file)
    do_reopen_db(file)

    {:noreply, file}
  end

  def handle_cast(request, state) do
    super(request, state)
  end

  ##########################################################
  # API Implementation Functions
  ##########################################################

  defp do_create_table(file, type) do
    case :dets.open_file(file, type) do
      {:error, reason} ->
        Logger.error(fn -> "Exited: #{inspect(reason)}" end)
        {:error, reason}

      {:ok, a} ->
        {:ok, a}
    end
  end

  defp do_handle_call_get(file, key) do
    case :dets.lookup(file, key) do
      {:error, reason} ->
        Logger.error(reason)
        {:error, reason}

      [{_key, value}] ->
        {:ok, value}

      [] ->
        {:empty, []}
    end
  end

  defp do_handle_call_put(file, {key, payload}) do
    case :dets.insert(file, {key, payload}) do
      :ok ->
        # Logger.info("insert_new returned true, state #{account}")
        {:ok, payload}

      error ->
        Logger.error("insert returned error #{error}")
        {:error, error}
    end
  end

  defp do_close_db(file) do
    result = :dets.close(file)
    {result}
  end

  defp do_backup_db(file) do
    {{y, mo, d}, {h, mi, s}} = :calendar.local_time()
    result = File.cp!(file, "#{file}.bak.#{y}_#{mo}_#{d}-#{h}_#{mi}_#{s}")
    {result}
  end

  defp do_reopen_db(file) do
    result = :dets.open_file(file, type: :set, ram_file: true)
    {result}
  end
end
