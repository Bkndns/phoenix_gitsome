defmodule Gitsome.GithubTaskerSupervisorTest do
  use ExUnit.Case, async: true

  # alias Gitsome.Helper
  alias Gitsome.GithubEtsCache, as: Cache
  alias Gitsome.GithubTasker

  '''
  Сценарий такой:
  запускается кеш
  запускается таскер
  при старте таскера - запускается парсинг
  парсинг наполняет кеш
  после устанавливается ттл кеша 24часа с проверкой каждые н минут
  проверка - если кеш актуален не делаем ничего
  если кеш устарел - запускаем парсинг
  еще одна проверка если кеш пуст - автоматически запускаем парсинг
  эта проверка на случай если упал супервизор кеша
  Именно так и работает Tasker
  '''

  @table :time_storage
  # @actual_time 1200 # 86400
  # @check_cache_interval 10 * 60 * 1000

  setup do
    # start_supervised({Gitsome.GithubEtsCache, []})
    # stop_supervised(Gitsome.GithubEtsCache)
    child_spec = %{
      id: EtsCache,
      start: {Gitsome.GithubEtsCache, :start_link, [[], [name: EtsCache]]}
    }

    pid = start_supervised!(child_spec)

    on_exit(fn -> Cache.clear_all_table_data() end)
    on_exit(fn -> Cache.clear_all_table_data(pid) end)
    on_exit(fn -> :ets.insert(@table, {:final_time, (DateTime.utc_now() |> DateTime.to_unix)}) end)

    {:ok, pid: pid}
  end


  # псевдо парсинг
  def parser_func(pid \\ []) do
    fill_cache(pid)
    :parsed_successful
  end

  # псевдо заполнение кеша
  def fill_cache(pid \\ []) do
    data1 = [
      %{
        "category" => "Actors",
        "category_description" => "Actors something",
        "id" => "actors",
        "max_stars" => "666",
        "min_stars" => "1",
        "repositories" => %{}
      }
    ]
    Cache.insert_data(:user1, data1, pid)
  end

  def _set_cache_ttl(plus_time) do
    time_for_check = plus_time
    unix_now = DateTime.utc_now() |> DateTime.to_unix
    final_time = time_for_check + unix_now
    :ets.insert(@table, {:final_time, final_time})
    final_time
  end






  # Начать парсить если кеш не актуален
  test "if cache is not actual", %{pid: pid} do
    # IO.inspect(pid)
    _ts = _set_cache_ttl(0)
    final_timestamp = GithubTasker._get_final_time_from_ets()
    is_actual_cache = GithubTasker.cache_is_actual?(final_timestamp)

    assert is_actual_cache == false

    if is_actual_cache == false do
      assert parser_func(pid) == :parsed_successful
      # IO.inspect(parser_func(pid))
    end
  end

  # если кеш актуален - делать что-то другое на не парсить заного
  test "if cache is actual", %{pid: pid} do
    _ts = _set_cache_ttl(3)
    final_timestamp = GithubTasker._get_final_time_from_ets()
    is_actual_cache = GithubTasker.cache_is_actual?(final_timestamp)

    assert is_actual_cache == true

    check = if is_actual_cache == false do
      parser_func(pid)
    else
      :do_something_but_not_parsing
    end
    assert check == :do_something_but_not_parsing
  end

  # Если кеш пуст - упал супервизор кеша
  test "if cache is empty Supervisor restart", %{pid: pid} do
    # IO.inspect(pid)

    cache_is_empty = Cache.table_is_empty?(pid)
    assert cache_is_empty == true
    parser_func(pid)
    data = Cache.get_one_table_data(:user1, pid)
    assert data != []


    # STOP SUPERVISOR
    stop_supervised(EtsCache)
    Cache.clear_all_table_data()


    child_spec = %{
      id: EtsCache,
      start: {Gitsome.GithubEtsCache, :start_link, [[], [name: EtsCache]]}
    }
    # START SUPERVISOR
    pid = start_supervised!(child_spec)
    # IO.inspect(pid)


    ###################################################

    cache_is_empty = Cache.table_is_empty?(pid)
    # IO.inspect(Cache.get_one_table_data(:user1, pid))
    assert cache_is_empty == true

    if cache_is_empty == true do

      parser_func(pid)
      _set_cache_ttl(3)

      final_timestamp = GithubTasker._get_final_time_from_ets()
      is_actual_cache = GithubTasker.cache_is_actual?(final_timestamp)

      assert is_actual_cache == true
    end

    data = Cache.get_one_table_data(:user1, pid)
    {:user1, [content]} = List.first(data)

    # Если эти данные есть, значит парсер запустился
    assert data != []
    assert content["category"] == "Actors"
    assert content["max_stars"] == "666"

  end

end
