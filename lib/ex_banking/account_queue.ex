defmodule ExBanking.AccountQueue do
  use Agent

  @operation_limit 10

  def start_link(user) do
    Agent.start_link(fn -> 0 end, name: modify_user(user))
  end

  def increase(user) do
    Agent.get_and_update(modify_user(user), fn operations ->
      if operations < @operation_limit do
        {operations + 1, operations + 1}
      else
        {nil, operations}
      end
    end)
  end

  def decrease(user) do
    Agent.cast(modify_user(user), &(&1 - 1))
  end

  defp modify_user(user) do
    String.to_atom(user <> to_string(__MODULE__))
  end
end
