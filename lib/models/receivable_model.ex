defmodule ReceivableModel do
  defstruct type: "Dues", amount: 0.0
end

defimpl String.Chars, for: ReceivableModel do
  def to_string(a) do
    inspect(a)
  end
end
