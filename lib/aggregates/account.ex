defmodule Account do
  require Datastore
  use GenServer
  require Logger
  @registry_name :accounts_registry

  def start_link(account_id) do
    name = via_tuple(account_id)
    account = %AccountModel{account_number: account_id}

    state =
      case Datastore.get(:db, account) do
        {:ok, value} ->
          #Logger.info("Starting Up #{account_id} has state #{value}")
          value

        {:empty, []} ->
          #Logger.info("Starting Up #{account_id} is empty")
          account

        {:error, reason} ->
          Logger.error("Starting Up #{account_id} has an error #{reason}")
          throw(reason)
      end

    GenServer.start_link(__MODULE__, [state], name: name)
  end

  def init([state]) do
    init(state)
  end

  def init(%AccountModel{} = state) do
    {:ok, state}
  end

  defp via_tuple(account_id) do
    {:via, Registry, {@registry_name, account_id}}
  end

  ##########################################################
  # Client API
  ##########################################################

  def create(account_id, %AccountModel{} = a) do
    GenServer.call(via_tuple(account_id), {:create, a})
  end

  def assess_receivable(account_id, %ReceivableModel{} = r, timeout \\ 5000) do
    GenServer.call(via_tuple(account_id), {:assess_receivable, r}, timeout)
  end

  def get_state(account_id, timeout \\ 5000) do
    GenServer.call(via_tuple(account_id), {:get_state}, timeout)
  end

  ##########################################################
  # Callbacks
  ##########################################################

  def handle_call({:get_state}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call({:assess_receivable, receivable}, _from, state) do
    {newbal, event} = apply_receivable(state, receivable)
    newevents = [event | state.events]
    newstate = %{state | current_balance: newbal}
    newstate = %{newstate | events: newevents}

    case Datastore.put(:db, newstate) do
      {:ok, saved} ->
       #Logger.info("New ETS State #{saved}")
        {:reply, {:ok, saved}, saved}

      {_, error} ->
       #Logger.error("Error saving account to ETS  #{error}")
        {:reply, {:error, error}, state}
    end
  end

  def handle_call({:create, account}, _, _) do
    {:ok, newstate} = Datastore.put(:db, account)
    ## account becomes state
    {:reply, {:ok, newstate}, newstate}
  end

  def handle_cast(request, state) do
    super(request, state)
  end

  defp apply_receivable(%AccountModel{} = a, r) do
    # TODO: fancy business rules here
    amount = a.current_balance + r.amount

    event = %DomainEventModel{
      event: "Assessed a #{r.type} receivable #{r.amount}. The balance is: #{amount}"
    }

    {amount, event}
  end
end
