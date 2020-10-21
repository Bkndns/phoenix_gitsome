defmodule Gitsome.ParsingFullTest do
  use ExUnit.Case, async: true

  # alias Gitsome.Helper
  alias Gitsome.GithubEtsCache, as: Cache
  alias Gitsome.GithubTasker

  setup do
    # start_supervised({Gitsome.GithubEtsCache, []})
    # stop_supervised(Gitsome.GithubEtsCache)
    on_exit(fn -> Cache.clear_all_table_data() end)
  end

  # Тест полного парсинга. Самая долгая операция. Нужно ждать, около 1.5 минуты, чтобы заполнился кеш. Поэтому вынесено в отдельную папку
  @moduletag timeout: :infinity
  @tag timeout: :infinity
  describe "Test Full Parsing" do

    # Псевдо, потому что парсинг, затратная по времени операция
    def parsing() do
      # GithubTasker.parse_awesome_repo() # Долгая операция
      Gitsome.GitHub.parse_awesome_list()
      :timer.sleep(90_000) # Долгая операция
    end



    test "Tasker Parser test" do
      # проверить, что кеш пустой перед запуском тестирования
      assert Cache.table_exist?() == true
      assert Cache.table_is_empty?() == true
      assert Cache.get_one_table_data(:actors) == []

      parsing()

      # после парсинга кеш таблица будет заполнена, можно получать значения
      assert Cache.get_one_table_data("Actors") != []
      assert Cache.get_one_table_data("Caching") != []
      assert Cache.get_one_table_data("Applications") != []
      assert Cache.get_one_table_data("Benchmarking") != []
      assert Cache.get_one_table_data("Behaviours and Interfaces") != []
      assert Cache.get_one_table_data("Encoding and Compression") != []
      assert Cache.get_one_table_data("Framework Components") != []
      assert Cache.get_one_table_data("Frameworks") != []
      assert Cache.get_one_table_data("HTML") != []
      assert Cache.get_one_table_data("HTTP") != []
    end

  end



end
