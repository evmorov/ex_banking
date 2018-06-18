defmodule ExBanking.Account.Mailbox do
  @limit 10

  def start_link(user) do
    Agent.start_link(fn -> 0 end, name: mailbox_name(user))
  end

  def increase(user) do
    Agent.get_and_update(mailbox_name(user), fn length ->
      if length < @limit do
        updated_length = length + 1
        {{:ok, updated_length}, updated_length}
      else
        {{:error, :too_many_requests_to_user}, length}
      end
    end)
  end

  def decrease(user) do
    Agent.cast(mailbox_name(user), &(&1 - 1))
  end

  defp mailbox_name(user) do
    (Atom.to_string(user) <> to_string(__MODULE__))
    |> String.to_atom()
  end
end
