defmodule ExBanking.Account do
  use GenServer

  defstruct(balance: %{})

  # Client

  def start_link(user) when is_binary(user) do
    user = String.to_atom(user)

    if Process.whereis(user) do
      {:error, :user_already_exists}
    else
      {status, _pid} = GenServer.start_link(__MODULE__, nil, name: user)
      status
    end
  end

  def start_link(_user) do
    {:error, :wrong_arguments}
  end

  def init(_) do
    {:ok, %{}}
  end

  def deposit(user, amount, currency)
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    change_balance(user, amount, currency)
  end

  def deposit(_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end

  def withdraw(user, amount, currency)
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    change_balance(user, amount * -1, currency)
  end

  def withdraw(_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end

  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    send_message(user, {:get_balance, currency})
  end

  def get_balance(_user, _currency) do
    {:error, :wrong_arguments}
  end

  def send(from_user, to_user, amount, currency)
      when is_binary(from_user) and is_binary(to_user) and is_number(amount) and
             is_binary(currency) do
    new_balance_from_user = withdraw(from_user, amount, currency)

    if {:error, :user_does_not_exist} == new_balance_from_user do
      {:error, :sender_does_not_exist}
    else
      new_balance_to_user = deposit(to_user, amount, currency)

      if {:error, :user_does_not_exist} == new_balance_to_user do
        deposit(from_user, amount, currency)
        {:error, :receiver_does_not_exist}
      else
        {new_balance_from_user, new_balance_to_user}
      end
    end
  end

  def send(_from_user, _to_user, _amount, _currency) do
    {:error, :wrong_arguments}
  end

  defp change_balance(user, amount, currency) do
    send_message(user, {:change_balance, amount, currency})
  end

  defp send_message(user, message) do
    user = String.to_atom(user)

    if Process.whereis(user) do
      GenServer.call(user, message)
    else
      {:error, :user_does_not_exist}
    end
  end

  # Server

  def handle_call({:change_balance, amount, currency}, _from, account) do
    amount = Float.round(amount / 1, 2)
    current_balance = Map.get(account, currency, 0.0)
    new_balance = current_balance + amount

    if new_balance >= 0 do
      account = Map.put(account, currency, new_balance)
      {:reply, new_balance, account}
    else
      {:reply, {:error, :not_enough_money}, account}
    end
  end

  def handle_call({:get_balance, currency}, _from, account) do
    balance = Map.get(account, currency, 0.0)
    {:reply, balance, account}
  end
end
