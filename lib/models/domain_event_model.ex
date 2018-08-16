defmodule DomainEventModel do
  defstruct event: nil, Date: :calendar.local_time()
end

defimpl String.Chars, for: DomainEvent do
  def to_string(d) do
    inspect(d)
  end
end
