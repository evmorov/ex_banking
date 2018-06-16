defmodule ExBanking do
  alias ExBanking.Account

  def create_user(user) do
    Account.start_link(user)
  end

  def deposit(user, amount, currency, delay \\ 0) do
    Account.deposit(user, amount, currency, delay)
  end

  def withdraw(user, amount, currency, delay \\ 0) do
    Account.withdraw(user, amount, currency, delay)
  end

  def get_balance(user, currency, delay \\ 0) do
    Account.get_balance(user, currency, delay)
  end

  def send(from_user, to_user, amount, currency, delay \\ 0) do
    Account.send(from_user, to_user, amount, currency, delay)
  end
end
