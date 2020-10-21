defmodule Gitsome.GithubTaskerTest do
  use ExUnit.Case, async: true

  # alias Gitsome.Helper
  alias Gitsome.GithubEtsCache, as: Cache
  alias Gitsome.GithubTasker

  setup do
    # start_supervised({Gitsome.GithubEtsCache, []})
    # stop_supervised(Gitsome.GithubEtsCache)
    on_exit(fn -> Cache.clear_all_table_data() end)
  end

  describe "Функции Taskera" do

    # @table :time_storage
    @actual_time 86400
    # @check_cache_interval 10 * 60 * 1000

    # setup do
      # test "Set cache ttl in table"
      # {:ok, cache_time: GithubTasker.set_cache_ttl()}
      # IO.inspect(GithubTasker._get_final_time_from_ets)
    # end

    def return_final_time() do
      unix_now = DateTime.utc_now() |> DateTime.to_unix
      time_for_check = @actual_time
      final_time = time_for_check + unix_now
      final_time
    end

    test "Check cache ttl before parse" do
      # Установили и записали ttl
      GithubTasker.set_cache_ttl()
      timest = return_final_time()
      # Получить то, что записали
      assert timest == GithubTasker._get_final_time_from_ets()
      # Пока кеш актуален, парситься не будет. Кеш актуален @actual_time
      assert GithubTasker.parse_awesome_repo() == :ok
    end

    test "Set cache ttl check" do
      # Установили и записали ttl
      GithubTasker.set_cache_ttl()
      timest = return_final_time()
      # Получить то, что записали
      assert timest == GithubTasker._get_final_time_from_ets()
    end

    test "Get and check cache ttl function" do
      # IO.inspect(Process.whereis(GithubTasker))
      GithubTasker.set_cache_ttl()
      final_time = return_final_time()
      assert GithubTasker._get_final_time_from_ets() == final_time
    end

    test "Check cache is actual?" do
      final_time = return_final_time() - 86401
      assert GithubTasker.cache_is_actual?(final_time) == false
      assert GithubTasker.cache_is_actual?(return_final_time()) == true
      assert GithubTasker.cache_is_actual?(0) == false
    end

    test "Check cache time since function" do
      final_time_c = return_final_time() - (DateTime.utc_now() |> DateTime.to_unix)
      assert GithubTasker.cache_time_since(return_final_time()) == final_time_c
    end

  end



end
