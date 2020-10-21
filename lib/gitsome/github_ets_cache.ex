defmodule Gitsome.GithubEtsCache do

  use GenServer

  @moduledoc """
  Простой кэш, использующий ETS.
  Без срока давности, сразу перезапись
  """

  '''
  alias Gitsome.GithubEtsCache, as: Cache
  Cache.start_link
  Cache.table_exist?
  Cache.table_is_empty?
  Cache.get_table_name

  Cache.insert_data(:users2, %{name: "K", lastname: "Ko", age: 25, gender: "female", car: "Tayota", phone: "iPhone 11"})
  Cache.get_all_table_data
  Cache.get_one_table_data("GUI")

  Cache.clear_all_table_data
  Cache.recreate_table
  '''

  @table :repository_info_storage

  defp is_table_create? do
    Enum.member?(:ets.all(), @table)
  end

  defp create_table do
    :ets.new(@table, [:ordered_set, :named_table, :public, read_concurrency: true, write_concurrency: true])
  end

  # # # # #

  defp _recreate_table do
    :ets.delete(@table)
    create_table()
  end

  defp _insert_data(key, value) do
    :ets.insert(@table, {key, value})
  end

  defp _clear_all_table_data do
    :ets.delete_all_objects(@table)
  end

  defp _get_all_table_data do
    all_info = :ets.tab2list(@table)
    all_info
  end

  defp _get_one_table_data(category) do
    repo_info = :ets.lookup(@table, category)
    repo_info
  end

  # # # # #


  ### GenServer API

  def init(state) do
    if !is_table_create?() do
      create_table()
    end
    {:ok, state}
  end


  def handle_call(:table_exist, _from, state) do
    func = is_table_create?()
    {:reply, func, state}
  end

  def handle_call(:table_is_empty, _from, state) do
    func = :ets.info(@table, :size)
    return = if func == 0, do: true, else: false
    {:reply, return, state}
  end

  def handle_call(:get_table_name, _from, state) do
    {:reply, @table, state}
  end

  def handle_call(:recreate_table, _from, state) do
    func = _recreate_table()
    {:reply, func, state}
  end

  def handle_call(:get_all_table_data, _from, state) do
    func = _get_all_table_data()
    {:reply, func, state}
  end

  def handle_call({:get_one_table_data, category}, _from, state) do
    func = _get_one_table_data(category)
    {:reply, func, state}
  end

  def handle_cast({:insert_data, key, value}, state) do
    _insert_data(key, value)
    {:noreply, state}
  end

  def handle_cast(:clear_all_table_data, state) do
    _clear_all_table_data()
    {:noreply, state}
  end

  ### Клиентский API

  def start_link(state \\ [], opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
		GenServer.start_link(__MODULE__, state, name: name)
  end

  def table_exist?(supervisor_name \\ __MODULE__) do
    GenServer.call(supervisor_name, :table_exist)
  end

  def table_is_empty?(supervisor_name \\ __MODULE__) do
    GenServer.call(supervisor_name, :table_is_empty)
  end

  def get_table_name(supervisor_name \\ __MODULE__) do
    GenServer.call(supervisor_name, :get_table_name)
  end

  def recreate_table(supervisor_name \\ __MODULE__) do
    GenServer.call(supervisor_name, :recreate_table)
  end

  def insert_data(key, value, supervisor_name \\ __MODULE__) do
    GenServer.cast(supervisor_name, {:insert_data, key, value})
  end

  def clear_all_table_data(supervisor_name \\ __MODULE__) do
    GenServer.cast(supervisor_name, :clear_all_table_data)
  end

  def get_all_table_data(supervisor_name \\ __MODULE__) do
    GenServer.call(supervisor_name, :get_all_table_data)
  end

  def get_one_table_data(category, supervisor_name \\ __MODULE__) do
    GenServer.call(supervisor_name, {:get_one_table_data, category})
  end

end
