defmodule Gitsome.ParsingOneCatTest do
  use ExUnit.Case, async: true

  # alias Gitsome.Helper
  alias Gitsome.GithubEtsCache, as: Cache
  alias Gitsome.GithubTasker

  setup do
    # start_supervised({Gitsome.GithubEtsCache, []})
    # stop_supervised(Gitsome.GithubEtsCache)
    on_exit(fn -> Cache.clear_all_table_data() end)
  end

  describe "Тест Парсинга. Долгая операция. Нужно ждать, чтобы заполнился кеш. Поэтому вынесено в отдельную папку" do

    # setup do
      # test "Set cache ttl in table"
      # {:ok, cache_time: GithubTasker.set_cache_ttl()}
      # IO.inspect(GithubTasker._get_final_time_from_ets)
    # end


    # Псевдо, потому что парсинг, затратная по времени операция
    def parsing() do
      # GithubTasker.parse_awesome_repo() # Долгая операция

      # Схема одной категории
      scheme_actors = " Actors\n*Libraries and tools for working with actors and such.*\n\n* [dflow](https://github.com/dalmatinerdb/dflow) - Pipelined flow processing engine.\n* [exactor](https://github.com/sasa1977/exactor) - Helpers for easier implementation of actors in Elixir.\n* [exos](https://github.com/awetzel/exos) - A Port Wrapper which forwards cast and call to a linked Port.\n* [flowex](https://github.com/antonmi/flowex) - Railway Flow-Based Programming with Elixir GenStage.\n* [mon_handler](https://github.com/tattdcodemonkey/mon_handler) - A minimal GenServer that monitors a given GenEvent handler.\n* [pool_ring](https://github.com/camshaft/pool_ring) - Create a pool based on a hash ring.\n* [poolboy](https://github.com/devinus/poolboy) - A hunky Erlang worker pool factory.\n* [pooler](https://github.com/seth/pooler) - An OTP Process Pool Application.\n* [sbroker](https://github.com/fishcakez/sbroker) - Sojourn-time based active queue management library.\n* [workex](https://github.com/sasa1977/workex) - Backpressure and flow control in EVM processes.\n\n"
      scheme_cache = " Caching\n*Libraries for caching data.*\n\n* [cachex](https://github.com/whitfin/cachex) - A powerful caching library for Elixir with a wide featureset.\n* [con_cache](https://github.com/sasa1977/con_cache) - ConCache is an ETS based key/value storage.\n* [elixir_locker](https://github.com/tsharju/elixir_locker) - Locker is an Elixir wrapper for the locker Erlang library that provides some useful libraries that should make using locker a bit easier.\n* [gen_spoxy](https://github.com/SpotIM/gen_spoxy) - Caching made fun.\n* [jc](https://github.com/jr0senblum/jc) - In-memory, distributable cache with pub/sub, JSON-query and consistency support.\n* [locker](https://github.com/wooga/locker) - Atomic distributed \"check and set\" for short-lived keys.\n* [lru_cache](https://github.com/arago/lru_cache) - Simple LRU Cache, implemented with ets.\n* [memoize](https://github.com/melpon/memoize) - A memoization macro that easily cache function.\n* [nebulex](https://github.com/cabol/nebulex) - A fast, flexible and extensible distributed and local caching library for Elixir.\n* [stash](https://github.com/whitfin/stash) - A straightforward, fast, and user-friendly key/value store.\n\n"

      Task.async(fn -> Gitsome.GitHub.prepare_each_one(scheme_actors) end)
      Task.async(fn -> Gitsome.GitHub.prepare_each_one(scheme_cache) end)

      :timer.sleep(6000) # Долгая операция
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
    end


    test "Parsing Error Item Check on Nil" do
      # Если репозитория не существует(или ошибка адреса) то он не будет спаршен
      # проверить, что кеш пустой перед запуском тестирования
      assert Cache.table_exist?() == true
      assert Cache.table_is_empty?() == true
      # У dflow ошибочный адрес - проверим: спарсится ли репозиторий dflow
      scheme = " Actors\n*Libraries and tools for working with actors and such.*\n\n* [dflow](https://github.com/dalmatinerdb9999/dflow56776hhh5665) - Pipelined flow processing engine.\n* [exactor](https://github.com/sasa1977/exactor) - Helpers for easier implementation of actors in Elixir.\n\n"

      Gitsome.GitHub.prepare_each_one(scheme)
      get_cache = Cache.get_one_table_data("Actors")
      assert get_cache != []
      items = List.first(get_cache)
      {_, [category]} = items
      assert category["category"] == "Actors"
      all_repo = Enum.map(category["repositories"], fn x -> x["repo_name"] end)
      assert "exactor" in all_repo == true
      # проверка на существование dflow
      refute "dflow" in all_repo == true
    end


    test "Parsing Error Category with bad Repository" do
      assert Cache.table_exist?() == true
      assert Cache.table_is_empty?() == true
      # У этой категории только один репозиторий
      # Репозиторий не ведет на GitHub
      # Как следствие категория получается пуста, в списке отображается пустая
      # Это не хорошо. Поэтому такие категории в список не добавляются
      scheme_6 = " Embedded Systems\n*Embedded systems development.*\n\n* [nerves](http://nerves-project.org) - A framework for writing embedded software in Elixir.\n\n"
      Gitsome.GitHub.prepare_each_one(scheme_6)
      get_cache = Cache.get_one_table_data("Embedded Systems")
      assert get_cache == []
    end

  end



end
