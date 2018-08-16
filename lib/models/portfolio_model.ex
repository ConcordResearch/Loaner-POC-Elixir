defmodule PortfolioModel do
  defstruct portfolio_number: "P", current_balance: 0.0, events: %DomainEventModel{}, accounts: []
end

defimpl String.Chars, for: PortfolioModel do
  def to_string(p) do
    inspect(p)
  end
end
