defmodule ExBankingTest do
  use ExUnit.Case, async: true
  doctest ExBanking

  test "create_user" do
    assert :ok == ExBanking.create_user("Bob")
  end

  test "2 decimal precision" do
    ExBanking.create_user("Bob")
    assert ExBanking.deposit("Bob", 1.2345, "RUB") == 1.23
    assert ExBanking.withdraw("Bob", 0.1, "RUB") == 1.13
    assert ExBanking.get_balance("Bob", "RUB") == 1.13
  end

  test "deposit" do
    ExBanking.create_user("Bob")
    assert ExBanking.deposit("Bob", 100, "RUB") == 100
    assert ExBanking.deposit("Bob", 5, "RUB") == 105
    assert ExBanking.get_balance("Bob", "RUB") == 105
    assert ExBanking.deposit("Bob", 3, "USD") == 3

    ExBanking.create_user("Martin")
    assert ExBanking.deposit("Martin", 66, "RUB") == 66
  end

  test "withdraw" do
    ExBanking.create_user("Bob")
    assert ExBanking.deposit("Bob", 100, "RUB") == 100
    assert ExBanking.withdraw("Bob", 5, "RUB") == 95
    assert ExBanking.get_balance("Bob", "RUB") == 95
    assert ExBanking.deposit("Bob", 100, "USD") == 100
    assert ExBanking.withdraw("Bob", 150, "USD") == 0

    ExBanking.create_user("Martin")
    assert ExBanking.deposit("Martin", 100, "RUB") == 100
    assert ExBanking.withdraw("Martin", 50, "RUB") == 50
  end

  test "get_balance" do
    ExBanking.create_user("Bob")
    assert ExBanking.get_balance("Bob", "RUB") == 0
    ExBanking.deposit("Bob", 5, "RUB")
    assert ExBanking.get_balance("Bob", "RUB") == 5
  end

  test "send" do
    ExBanking.create_user("Bob")
    ExBanking.deposit("Bob", 100, "RUB")
    ExBanking.create_user("Martin")
    ExBanking.deposit("Martin", 50, "RUB")

    assert {90, 60} == ExBanking.send("Bob", "Martin", 10, "RUB")
    assert ExBanking.get_balance("Bob", "RUB") == 90
    assert ExBanking.get_balance("Martin", "RUB") == 60
  end
end
