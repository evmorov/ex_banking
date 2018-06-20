defmodule ExBanking.Account do
  use GenServer

  alias ExBanking.Account.QueueLength

  # Client

  def start_link(user) when is_binary(user) do
    case GenServer.start_link(__MODULE__, account_name(user), name: account_name(user)) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> {:error, :user_already_exists}
    end
  end

  def start_link(_user) do
    {:error, :wrong_arguments}
  end

  def init(account_name) do
    with {:ok, _pid} <- QueueLength.start_link(account_name), do: {:ok, %{}}
  end

  def deposit(user, amount, currency, delay)
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    send_message(user, {:change_balance, amount, currency, delay})
  end

  def deposit(_user, _amount, _currency, _delay) do
    {:error, :wrong_arguments}
  end

  def withdraw(user, amount, currency, delay)
      when is_binary(user) and is_number(amount) and is_binary(currency) do
    send_message(user, {:change_balance, amount * -1, currency, delay})
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
      when is_binary(from_user) and is_binary(to_user) and is_number(amount) and is_binary(currency) do
    new_balance_from_user = withdraw(from_user, amount, currency, delay)

    case new_balance_from_user do
      {:error, :user_does_not_exist} -> {:error, :sender_does_not_exist}
      {:error, :too_many_requests_to_user} -> {:error, :too_many_requests_to_sender}
      err = {:error, _} -> err
      _ -> send_withdrawn(from_user, to_user, amount, currency, new_balance_from_user, delay)
    end
  end

  def send(_from_user, _to_user, _amount, _currency, _delay) do
    {:error, :wrong_arguments}
  end

  defp send_withdrawn(from_user, to_user, amount, currency, new_balance_from_user, delay) do
    new_balance_to_user = deposit(to_user, amount, currency, delay)

    case new_balance_to_user do
      {:error, message} ->
        # return money back
        deposit(from_user, amount, currency, delay)

        case message do
          :user_does_not_exist -> {:error, :receiver_does_not_exist}
          :too_many_requests_to_user -> {:error, :too_many_requests_to_receiver}
          message -> message
        end

      _ ->
        {new_balance_from_user, new_balance_to_user}
    end
  end

  defp send_message(user, message) do
    if Process.whereis(account_name(user)) do
      send_message_for_existing_account(account_name(user), message)
    else
      {:error, :user_does_not_exist}
    end
  end

  defp send_message_for_existing_account(account_name, message) do
    with {:ok, _} <- QueueLength.increase(account_name) do
      reply = GenServer.call(account_name, message)
      QueueLength.decrease(account_name)
      reply
    end
  end

  defp account_name(user) do
    String.to_atom(user)
  end

  # Server

  def handle_call({:get_balance, currency, delay}, _from, account) do
    Process.sleep(delay)

    balance = Map.get(account, currency, 0.0)
    {:reply, balance, account}
  end

  def handle_call({:change_balance, amount, currency, delay}, _from, account) do
    Process.sleep(delay)

    new_balance = Map.get(account, currency, 0.0) + Float.round(amount / 1, 2)
    change_balance(account, currency, new_balance)
  end

  defp change_balance(account, currency, new_balance) when new_balance >= 0 do
    {:reply, new_balance, Map.put(account, currency, new_balance)}
  end

  defp change_balance(account, _currency, _new_balance) do
    {:reply, {:error, :not_enough_money}, account}
  end
end
