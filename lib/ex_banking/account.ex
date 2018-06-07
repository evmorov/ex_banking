defmodule ExBanking.Account do
  use GenServer

  defstruct(balance: %{})

  # Client

  def start_link(user) do
    user = String.to_atom(user)
    if Process.whereis(user) do
      :user_already_exists
    else
      {status, _pid} = GenServer.start_link(__MODULE__, nil, name: user)
      status
    end
  end

  def init(_) do
    {:ok, %{}}
  end

  def deposit(user, amount, currency) do
    user = String.to_atom(user)
    if Process.whereis(user) do
      GenServer.call(user, {:deposit, amount, currency})
    else
      :user_does_not_exist
    end
  end

  def withdraw(user, amount, currency) do
    user = String.to_atom(user)
    if Process.whereis(user) do
      GenServer.call(user, {:withdraw, amount, currency})
    else
      :user_does_not_exist
    end
  end

  def get_balance(user, currency) do
    user
    |> String.to_atom()
    |> GenServer.call({:get_balance, currency})
  end

  # Server

  def handle_call({:deposit, amount, currency}, _from, account) do
    amount = (amount / 1) |> Float.round(2)
    current_balance = Map.get(account, currency, 0.0)
    new_balance = current_balance + amount
    account = Map.put(account, currency, new_balance)
    {:reply, new_balance, account}
  end

  def handle_call({:withdraw, amount, currency}, _from, account) do
    amount = (amount / 1) |> Float.round(2)
    current_balance = Map.get(account, currency, 0.0)
    new_balance = current_balance - amount
    if new_balance >= 0 do
      account = Map.put(account, currency, new_balance)
      {:reply, new_balance, account}
    else
      {:reply, :not_enough_money, account}
    end
  end

  def handle_call({:get_balance, currency}, _from, account) do
    balance = Map.get(account, currency, 0.0)
    {:reply, balance, account}
  end
end
