defmodule AccountModel do
  defstruct account_number: "A", current_balance: 0.0, events: [%DomainEventModel{}]
end

defimpl String.Chars, for: AccountModel do
  def to_string(a) do
    inspect(a)
  end
end
