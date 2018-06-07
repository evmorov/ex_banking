defmodule ExBanking.Account do
  use GenServer

  defstruct(balance: %{})

  # Client

  def start_link(user) when is_binary(user) do
    user = String.to_atom(user)

    if Process.whereis(user) do
      :user_already_exists
    else
      {status, _pid} = GenServer.start_link(__MODULE__, nil, name: user)
      status
    end
  end

  def start_link(_user) do
    :wrong_arguments
  end

  def init(_) do
    {:ok, %{}}
  end

  def deposit(user, amount, currency)
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    user = String.to_atom(user)

    if Process.whereis(user) do
      GenServer.call(user, {:deposit, amount, currency})
    else
      :user_does_not_exist
    end
  end

  def deposit(_user, _amount, _currency) do
    :wrong_arguments
  end

  def withdraw(user, amount, currency)
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    user = String.to_atom(user)

    if Process.whereis(user) do
      GenServer.call(user, {:withdraw, amount, currency})
    else
      :user_does_not_exist
    end
  end

  def withdraw(_user, _amount, _currency) do
    :wrong_arguments
  end

  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    user
    |> String.to_atom()
    |> GenServer.call({:get_balance, currency})
  end

  def get_balance(_user, _currency) do
    :wrong_arguments
  end

  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_number(amount) and
             is_binary(currency) do
    new_balance_from_user = withdraw(from_user, amount, currency)

    if new_balance_from_user == :user_does_not_exist do
      :sender_does_not_exist
    else
      new_balance_to_user = deposit(to_user, amount, currency)

      if new_balance_to_user == :user_does_not_exist do
        deposit(from_user, amount, currency)
        :receiver_does_not_exist
      else
        {new_balance_from_user, new_balance_to_user}
      end
    end
  end

  def send(_from_user, _to_user, _amount, _currency) do
    :wrong_arguments
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