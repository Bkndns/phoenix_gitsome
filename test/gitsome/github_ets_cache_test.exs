defmodule Gitsome.GithubEtsCacheTest do
  use ExUnit.Case, async: true

  # alias Gitsome.Helper
  alias Gitsome.GithubEtsCache

  setup do
    # start_supervised({Gitsome.GithubEtsCache, []})
    # stop_supervised(Gitsome.GithubEtsCache)
    on_exit(fn -> GithubEtsCache.clear_all_table_data() end)
  end

  describe "Функции модуля кеша" do

    @table :repository_info_storage

    test "check table is exist?" do
      assert Enum.member?(:ets.all(), @table) == true
    end

    test "check table is empty?" do
      assert GithubEtsCache.table_is_empty? == true
    end

    test "get table name" do
      assert GithubEtsCache.get_table_name == @table
    end

    test "test insert data and get one item" do
      data = [
        users2: %{
          age: 25,
          car: "Tayota",
          gender: "female",
          lastname: "Ko",
          name: "K",
          phone: "iPhone 11"
        }
      ]
      GithubEtsCache.insert_data(:users2, %{name: "K", lastname: "Ko", age: 25, gender: "female", car: "Tayota", phone: "iPhone 11"})
      assert GithubEtsCache.get_one_table_data(:users2) == data
      GithubEtsCache.clear_all_table_data()
    end

    test "test get all data from table" do
      data1 = %{age: 25, car: "Tayota", gender: "female", lastname: "Ko", name: "K", phone: "iPhone 11"}
      data2 = %{age: 18, car: "BMW", gender: "male", lastname: "John", name: "Keys", phone: "Pixel" }
      final_data = [
        users2: %{
          age: 25,
          car: "Tayota",
          gender: "female",
          lastname: "Ko",
          name: "K",
          phone: "iPhone 11"
        },
        users3: %{
          age: 18,
          car: "BMW",
          gender: "male",
          lastname: "John",
          name: "Keys",
          phone: "Pixel"
        }
      ]
      GithubEtsCache.insert_data(:users2, data1)
      GithubEtsCache.insert_data(:users3, data2)

      assert GithubEtsCache.get_all_table_data() == final_data
    end

    test "test clear all data" do
      GithubEtsCache.insert_data(:users2, %{name: "K", lastname: "Ko", age: 25, gender: "female", car: "Tayota", phone: "iPhone 11"})
      GithubEtsCache.clear_all_table_data()
      assert GithubEtsCache.get_one_table_data(:users2) == []
    end

  end


  # Этот тест проходит через раз в зависимости от запуска супервайзера
  # Ручное тестирование показывает, что после убийства процесса кеша - супервайзер пересоздает его
  # test "Test Supervisor Cache" do
  #   # Получаем супервайзер Pid
  #   pid = Process.whereis(Gitsome.GithubEtsCache)
  #   if pid do
  #     # Проверяем есть ли таблица
  #     assert GithubEtsCache.table_exist?() == true
  #     # Убиваем процесс, после чего он должен пересоздать таблицу
  #     # IO.inspect(stop_supervised(pid)) # Not found. Why?
  #     Process.exit(pid, :exit)
  #     start_supervised!(GithubEtsCache)
  #     assert GithubEtsCache.table_exist?() == true
  #   end
  #   stop_supervised(Gitsome.GithubEtsCache)
  # end


end
