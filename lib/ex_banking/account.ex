defmodule ExBanking.Account do
  use GenServer

  alias ExBanking.AccountQueue

  defstruct(balance: %{})

  # Client

  def start_link(user) when is_binary(user) do
    user_atom = String.to_atom(user)

    if Process.whereis(user_atom) do
      {:error, :user_already_exists}
    else
      # if status bad do not create queue
      AccountQueue.start_link(user)
      {status, _pid} = GenServer.start_link(__MODULE__, nil, name: user_atom)
      status
    end
  end

  def start_link(_user) do
    {:error, :wrong_arguments}
  end

  def init(_) do
    {:ok, %{}}
  end

  def deposit(user, amount, currency, delay)
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    change_balance(user, amount, currency, delay)
  end

  def deposit(_user, _amount, _currency, _delay) do
    {:error, :wrong_arguments}
  end

  def withdraw(user, amount, currency, delay)
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    change_balance(user, amount * -1, currency, delay)
  end

  def withdraw(_user, _amount, _currency, _delay) do
    {:error, :wrong_arguments}
  end

  def get_balance(user, currency, delay) when is_binary(user) and is_binary(currency) do
    send_message(user, {:get_balance, currency, delay})
  end

  def get_balance(_user, _currency, _delay) do
    {:error, :wrong_arguments}
  end

  def send(from_user, to_user, amount, currency, delay)
      when is_binary(from_user) and is_binary(to_user) and is_number(amount) and
             is_binary(currency) do
    new_balance_from_user = withdraw(from_user, amount, currency, delay)

    case new_balance_from_user do
      {:error, :user_does_not_exist} ->
        {:error, :sender_does_not_exist}

      {:error, :too_many_requests_to_user} ->
        {:error, :too_many_requests_to_sender}

      {:error, message} ->
        {:error, message}

      _ ->
        new_balance_to_user = deposit(to_user, amount, currency, delay)

        case new_balance_to_user do
          {:error, :user_does_not_exist} ->
            deposit(from_user, amount, currency, delay)
            {:error, :receiver_does_not_exist}

          {:error, :too_many_requests_to_user} ->
            deposit(from_user, amount, currency, delay)
            {:error, :too_many_requests_to_receiver}

          {:error, message} ->
            deposit(from_user, amount, currency, delay)
            {:error, message}

          _ ->
            {new_balance_from_user, new_balance_to_user}
        end
    end
  end

  def send(_from_user, _to_user, _amount, _currency, _delay) do
    {:error, :wrong_arguments}
  end

  defp change_balance(user, amount, currency, delay) do
    send_message(user, {:change_balance, amount, currency, delay})
  end

  defp send_message(user, message) do
    user_atom = String.to_atom(user)

    if Process.whereis(user_atom) do
      if AccountQueue.increase(user) do
        reply = GenServer.call(user_atom, message)
        AccountQueue.decrease(user)
        reply
      else
        {:error, :too_many_requests_to_user}
      end
    else
      {:error, :user_does_not_exist}
    end
  end

  # Server

  def handle_call({:change_balance, amount, currency, delay}, _from, account) do
    Process.sleep(delay)

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

  def handle_call({:get_balance, currency, delay}, _from, account) do
    Process.sleep(delay)

    balance = Map.get(account, currency, 0.0)
    {:reply, balance, account}
  end
end
