defmodule ExBanking do
  alias ExBanking.Account

  def create_user(user) do
    Account.start_link(user)
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
    Account.send(from_user, to_user, amount, currency)
  end
end
