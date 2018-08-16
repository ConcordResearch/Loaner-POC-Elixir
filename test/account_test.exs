defmodule AccountTest do
  use ExUnit.Case
  require ReceivableModel
  doctest DemoElixir.Application
  @number_of_accounts 120_000
  @billing_amount 100.00

  setup_all do
    #IO.puts("Number of Processes allowed #{System.get_env("ELIXIR_ERL_OPTS")}")
    #IO.puts("Number of Atoms allowed     #{:erlang.system_info(:atom_limit)}")

    on_exit(fn ->

      #IO.puts("Number of atoms before termination #{:erlang.system_info(:atom_count)}")
      Datastore.close(:test_db)

      Datastore.close(:db)

    end)
  end

  test "120K Performance Test: Create, Store, Bill" do
    find = fn {:ok, %AccountModel{account_number: num}} ->
      AccountSupervisor.find_or_create_process(num)
    end

    receivable = %ReceivableModel{type: "DuesTest", amount: @billing_amount}

    assess = fn {:ok, account_number} -> Account.assess_receivable(account_number, receivable) end

    number_of_accounts_before_test = AccountSupervisor.account_process_count()

    time_in_seconds =
      Benchmark.measure(fn ->
        1..@number_of_accounts
        |> Stream.map(&"TestAccount#{&1}")
        |> Stream.map(&%AccountModel{account_number: &1})
        |> Stream.map(&Datastore.put(:test_db, &1))
        |> Stream.map(&find.(&1))
        |> Stream.map(&assess.(&1))
        |> Stream.run()
      end)

    number_of_accounts_after_test = AccountSupervisor.account_process_count()

    IO.puts(
      "It took #{time_in_seconds} seconds to execute billing on #{@number_of_accounts} accounts."
    )

    IO.puts(
      "Number of accounts before test: #{number_of_accounts_before_test}, after test: #{
        number_of_accounts_after_test
      }"
    )

    balance_after_billing = get_account_states()
    expected_balance = @number_of_accounts * @billing_amount

    IO.puts(
      "Expecting $#{:erlang.float_to_binary(expected_balance, decimals: 3)} and got $#{
        :erlang.float_to_binary(balance_after_billing, decimals: 3)
      }"
    )
    assert expected_balance = balance_after_billing
    assert 31 >= time_in_seconds
  end

  defp get_account_states() do
    AccountSupervisor.account_numbers()
    |> Enum.map(&Account.get_state(&1))
    |> Enum.map(&get_current_balance(&1))
    |> Enum.sum()
  end

  defp get_current_balance({:ok, %AccountModel{current_balance: balance}}) do
    balance
  end
end
