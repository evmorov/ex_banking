defmodule ExBanking do
  alias ExBanking.Account

  def create_user(user) do
    {status, pid} = Account.start_link(user)
    status
  end

  def deposit(user, amount, currency) do
    Account.deposit(user, amount, currency)
  end

  def withdraw(user, amount, currency) do
    Account.withdraw(user, amount, currency)
  end

  def get_balance(user, currency) do
    Account.get_balance(user, currency)
  end

  def send(from_user, to_user, amount, currency) do
    new_balance_from_user = Account.withdraw(from_user, amount, currency)
    new_balance_to_user = Account.deposit(to_user, amount, currency)
    {new_balance_from_user, new_balance_to_user}
  end
end
