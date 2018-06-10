defmodule ExBankingTest do
  use ExUnit.Case, async: true
  doctest ExBanking

  describe "create_user/1" do
    test "creates a user" do
      assert ExBanking.create_user("Bob") == :ok
    end

    test "return error when trying to create a user with the same name" do
      ExBanking.create_user("Bob")
      assert ExBanking.create_user("Bob") == {:error, :user_already_exists}
    end

    test "user is case sensitive" do
      ExBanking.create_user("Bob")
      assert ExBanking.create_user("bob") == :ok
    end

    test "expects input in the defined format" do
      assert ExBanking.create_user(:bob) == {:error, :wrong_arguments}
      assert ExBanking.create_user(100) == {:error, :wrong_arguments}
      assert ExBanking.create_user(["Bob"]) == {:error, :wrong_arguments}
      assert ExBanking.create_user("Bob") == :ok
    end
  end

  describe "deposit/3" do
    test "increases amount of money on a bank account" do
      ExBanking.create_user("Bob")
      assert ExBanking.deposit("Bob", 100, "RUB") == 100
      assert ExBanking.deposit("Bob", 5, "RUB") == 105
      assert ExBanking.get_balance("Bob", "RUB") == 105
      assert ExBanking.deposit("Bob", 3, "USD") == 3

      ExBanking.create_user("Martin")
      assert ExBanking.deposit("Martin", 66, "RUB") == 66
    end

    test "money has 2 decimal precision" do
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

    test "expects input in the defined format" do
      ExBanking.create_user("Bob")

      assert ExBanking.deposit("Bob", "100", "RUB") == {:error, :wrong_arguments}
      assert ExBanking.deposit(:Bob, 100, "RUB") == {:error, :wrong_arguments}
      assert ExBanking.deposit("Bob", 100, :RUB) == {:error, :wrong_arguments}
      assert ExBanking.deposit("Bob", 5, "RUB") == 5
    end

    test "error if user doesn't exist" do
      assert ExBanking.deposit("Bob", 100, "RUB") == {:error, :user_does_not_exist}
    end
  end

  describe "withdraw" do
    test "decreases amount of money on a bank account" do
      ExBanking.create_user("Bob")
      assert ExBanking.deposit("Bob", 100, "RUB") == 100
      assert ExBanking.withdraw("Bob", 5, "RUB") == 95
      assert ExBanking.get_balance("Bob", "RUB") == 95

      ExBanking.create_user("Martin")
      assert ExBanking.deposit("Martin", 100, "RUB") == 100
      assert ExBanking.withdraw("Martin", 50, "RUB") == 50
    end

    test "expects input in the defined format" do
      ExBanking.create_user("Bob")
      assert ExBanking.deposit("Bob", 100, "RUB") == 100

      assert ExBanking.withdraw(:Bob, 5, "RUB") == {:error, :wrong_arguments}
      assert ExBanking.withdraw("Bob", "5", "RUB") == {:error, :wrong_arguments}
      assert ExBanking.withdraw("Bob", 5, :RUB) == {:error, :wrong_arguments}
      assert ExBanking.withdraw("Bob", 5, "RUB") == 95
    end

    test "error if user doesn't exist" do
      assert ExBanking.withdraw("Bob", 100, "RUB") == {:error, :user_does_not_exist}
    end

    test "error if not enough money" do
      ExBanking.create_user("Bob")
      ExBanking.deposit("Bob", 100, "RUB")
      assert ExBanking.withdraw("Bob", 101, "RUB") == {:error, :not_enough_money}
      assert ExBanking.get_balance("Bob", "RUB") == 100
    end
  end

  describe "get_balance/1" do
    test "return balance for a user" do
      ExBanking.create_user("Bob")
      assert ExBanking.get_balance("Bob", "RUB") == 0
      ExBanking.deposit("Bob", 5, "RUB")
      assert ExBanking.get_balance("Bob", "RUB") == 5
    end

    test "expects input in the defined format" do
      ExBanking.create_user("Bob")

      assert ExBanking.get_balance(:Bob, "RUB") == {:error, :wrong_arguments}
      assert ExBanking.get_balance("Bob", :RUB) == {:error, :wrong_arguments}
    end
  end

  describe "send/4" do
    test "transfers money from one user to another" do
      ExBanking.create_user("Bob")
      ExBanking.deposit("Bob", 100, "RUB")
      ExBanking.create_user("Martin")
      ExBanking.deposit("Martin", 50, "RUB")

      assert ExBanking.send("Bob", "Martin", 10, "RUB") == {90, 60}
      assert ExBanking.get_balance("Bob", "RUB") == 90
      assert ExBanking.get_balance("Martin", "RUB") == 60
    end

    test "expects input in the defined format" do
      ExBanking.create_user("Bob")
      ExBanking.deposit("Bob", 100, "RUB")
      ExBanking.create_user("Martin")
      ExBanking.deposit("Martin", 50, "RUB")

      assert ExBanking.send(:Bob, "Martin", 10, "RUB") == {:error, :wrong_arguments}
      assert ExBanking.send("Bob", :Martin, 10, "RUB") == {:error, :wrong_arguments}
      assert ExBanking.send("Bob", "Martin", "10", "RUB") == {:error, :wrong_arguments}
      assert ExBanking.send("Bob", "Martin", 10, :RUB) == {:error, :wrong_arguments}
      assert ExBanking.get_balance("Bob", "RUB") == 100
      assert ExBanking.get_balance("Martin", "RUB") == 50
    end

    test "returns error if sender doesn't exist" do
      ExBanking.create_user("Martin")

      assert ExBanking.send("Bob", "Martin", 10, "RUB") == {:error, :sender_does_not_exist}
      assert ExBanking.get_balance("Martin", "RUB") == 0
    end

    test "returns error if receiver doesn't exist" do
      ExBanking.create_user("Bob")
      ExBanking.deposit("Bob", 100, "RUB")

      assert ExBanking.send("Bob", "Martin", 10, "RUB") == {:error, :receiver_does_not_exist}
      assert ExBanking.get_balance("Bob", "RUB") == 100
    end
  end
end
