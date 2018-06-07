defmodule ExBankingTest do
  use ExUnit.Case, async: true
  doctest ExBanking

  test "create_user" do
    assert ExBanking.create_user("Bob") == :ok
  end

  test ":user_already_exists error" do
    ExBanking.create_user("Bob")
    assert ExBanking.create_user("Bob") == :user_already_exists
  end

  test "user is case sensitive" do
    ExBanking.create_user("Bob")
    assert ExBanking.create_user("bob") == :ok
  end

  test "2 decimal precision" do
    ExBanking.create_user("Bob")
    assert ExBanking.deposit("Bob", 1.2345, "RUB") == 1.23
    assert ExBanking.withdraw("Bob", 0.1, "RUB") == 1.13
    assert ExBanking.get_balance("Bob", "RUB") == 1.13
  end

  test "currency is case sensitive" do
    ExBanking.create_user("Bob")
    assert ExBanking.deposit("Bob", 100, "RUB") == 100
    assert ExBanking.deposit("Bob", 50, "Rub") == 50
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

  test ":user_does_not_exist error in deposit" do
    assert ExBanking.deposit("Bob", 100, "RUB") == :user_does_not_exist
  end

  test "withdraw" do
    ExBanking.create_user("Bob")
    assert ExBanking.deposit("Bob", 100, "RUB") == 100
    assert ExBanking.withdraw("Bob", 5, "RUB") == 95
    assert ExBanking.get_balance("Bob", "RUB") == 95

    ExBanking.create_user("Martin")
    assert ExBanking.deposit("Martin", 100, "RUB") == 100
    assert ExBanking.withdraw("Martin", 50, "RUB") == 50
  end

  test ":user_does_not_exist error in withdraw" do
    assert ExBanking.withdraw("Bob", 100, "RUB") == :user_does_not_exist
  end

  test ":not_enough_money error in withdraw" do
    ExBanking.create_user("Bob")
    ExBanking.deposit("Bob", 100, "RUB")
    assert ExBanking.withdraw("Bob", 101, "RUB") == :not_enough_money
    assert ExBanking.get_balance("Bob", "RUB") == 100
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

    assert ExBanking.send("Bob", "Martin", 10, "RUB") == {90, 60}
    assert ExBanking.get_balance("Bob", "RUB") == 90
    assert ExBanking.get_balance("Martin", "RUB") == 60
  end
end
