defmodule ExBanking.AccountQueue do
  use Agent

  def start_link(user) do
    Agent.start_link(fn -> 0 end, name: modify_user(user))
  end

  def increase(user) do
    Agent.get_and_update(modify_user(user), fn operations ->
      if operations < 10 do
        {operations + 1, operations + 1}
      else
        {nil, operations}
      end
    end)
  end

  def decrease(user) do
    Agent.cast(modify_user(user), fn operations -> operations - 1 end)
  end

  defp modify_user(user) do
    String.to_atom(user <> "Queue")
  end

  # def get(user) do
    # &(&1)
    # Agent.get(user, fn operations -> operations end)
  # end

  # def start_link(queue, name) do
  #   Agent.start_link(fn -> queue end, name: name)
  # end
  # def start_link(_opts) do
  #   Agent.start_link(fn -> %{} end)
  # end

  # def set(queue, item) do
  #   Agent.cast(queue, fn state -> state ++ [item] end)
  # end
  # def put(bucket, key, value) do
  #   Agent.update(bucket, &Map.put(&1, key, value))
  # end

  # def get(queue) do
  #   Agent.get_and_update(queue, fn [item | state] -> {item, state} end)
  # end
   # def get(bucket, key) do
   #  Agent.get(bucket, &Map.get(&1, key))
  # end
end
