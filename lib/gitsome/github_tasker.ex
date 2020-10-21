defmodule Gitsome.GithubTasker do

  use GenServer
  require Logger

  alias Gitsome.GithubEtsCache, as: Cache
  alias Gitsome.GitHub, as: GitHub

  @table :time_storage
  @actual_time 86400
  @check_cache_interval 2 * 60 * 1000

  @moduledoc """
  Модуль, который выполняет две задачи
  1. Может парсить ElixirAwesom Repository раз в сутки
  2. Следить за ttl кэша >= 86400
  """


  '''
  Gitsome.GithubTasker.parse_awesome_repo
  Gitsome.GithubTasker.set_cache_ttl()
  Gitsome.GithubTasker.cache_is_actual?(final_time)
  Gitsome.GithubTasker.cache_time_since(final_time)

  final_time = Gitsome.GithubTasker._get_final_time_from_ets()

  Process.whereis(Gitsome.GithubTasker) |> Process.exit(:exit)
  Process.whereis(Gitsome.GithubEtsCache) |> Process.exit(:exit)
  '''


  ### PRIVATE FUNCTIONS
  defp create_table do
    :ets.new(@table, [:ordered_set, :named_table, :public, read_concurrency: true, write_concurrency: true])
  end

  defp schedule_work() do
    Process.send_after(self(), :work, @check_cache_interval)
  end

  # Функция запускает длительный парсинг
  # После парсинга образуется кеш
  # Стартуем отслеживание кеша
  defp _parse_awesome_repo() do

    final_timestamp = _get_final_time_from_ets()
    if (final_timestamp == nil) || (final_timestamp == []) do

      # Если есть кэш, то не парсим
      cache_is_empty = Cache.table_is_empty?
      if cache_is_empty == true do
        Logger.warn("CACHE IS EMPTY!")
        ### PARSING
        _parse_function()
      end

      ### CACHE TTL
      _set_cache_ttl()
      schedule_work()
    end

  end

  # Просто функция парсинга, пригодится alias
  defp _parse_function() do
    GitHub.parse_awesome_list()
  end

  defp _set_cache_ttl() do
    time_for_check = @actual_time
    unix_now = DateTime.utc_now() |> DateTime.to_unix
    final_time = time_for_check + unix_now
    :ets.insert(@table, {:final_time, final_time})
    final_time
  end

  defp _cache_is_actual?(final_timestamp) do
    func = if (DateTime.utc_now() |> DateTime.to_unix) < final_timestamp, do: true, else: :false
    func
  end

  defp _cache_time_since(final_timestamp) do
    time_end = final_timestamp - (DateTime.utc_now() |> DateTime.to_unix)
    time_end
  end

  def _get_final_time_from_ets() do
    final_time = :ets.lookup(@table, :final_time)
    final_time[:final_time]
  end


  ### GenServer API
  def init(init_arg) do
    # Авто создание ttl таблицы
    create_table()
    # Автозапуск парсинга репозиториев
    # _parse_awesome_repo()
    {:ok, init_arg}
  end

  def handle_info(:work, state) do

    # записан ли ttl
    final_timestamp = _get_final_time_from_ets()

    # есть ли что-нибудь в кеше
    cache_is_empty = Cache.table_is_empty?
    if cache_is_empty == true do
      Logger.warn("CACHE IS EMPTY!")
      _parse_function()
    end

    # актуален ли кеш по ттл
    is_actual_cache = _cache_is_actual?(final_timestamp)
    if is_actual_cache == false do
      _parse_awesome_repo()
      # _parse_function()
      # _set_cache_ttl()
    else
      schedule_work()
    end

    cache_valid_seconds = _cache_time_since(final_timestamp)
    Logger.info("Cache valid #{cache_valid_seconds} seconds. Access app at http://localhost:4000", ansi_color: :green)

    {:noreply, state}
  end


  def handle_cast(:parse_awesome_repo, state) do
    _parse_awesome_repo()
    {:noreply, state}
  end

  def handle_call(:set_cache_ttl, _from, state) do
    final_time = _set_cache_ttl()
    {:reply, final_time, state}
  end

  def handle_call({:cache_time_since, final_timestamp}, _from, state) do
    time_end = _cache_time_since(final_timestamp)
    {:reply, time_end, state}
  end

  def handle_call({:cache_is_actual, final_timestamp}, _from, state) do
    func = _cache_is_actual?(final_timestamp)
    {:reply, func, state}
  end



  ### Клиентский API
  def start_link(state \\ []) do
		GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def parse_awesome_repo() do
    GenServer.cast(__MODULE__, :parse_awesome_repo)
  end

  def set_cache_ttl() do
    GenServer.call(__MODULE__, :set_cache_ttl)
  end

  def cache_time_since(final_timestamp) do
    GenServer.call(__MODULE__, {:cache_time_since, final_timestamp})
  end

  def cache_is_actual?(final_timestamp) do
    GenServer.call(__MODULE__, {:cache_is_actual, final_timestamp})
  end

end
