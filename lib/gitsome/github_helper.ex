defmodule Gitsome.Helper do

  @moduledoc """
  Простейшие вспомогательные функции к файлу github.ex
  """

  require Logger
  alias Gitsome.GithubEtsCache



  # Получаем владельца и название репозитория по ссылке (https://github.com/owner/repo_name)
  # Gitsome.Helper.get_repository_owner_and_name_by_full_url("https://github.com/edgurgel/httpoison")
  def get_repository_owner_and_name_by_full_url(repository_full_url)
  when is_binary(repository_full_url) do

    regex = ~r/https:\/\/github.com\/(?<repository_owner>[0-9a-zA-Z._-]+)\/(?<repository_name>[0-9a-zA-Z._-]+)/

    with %{
      "repository_owner" => repository_owner,
      "repository_name" => repository_name
      } <- Regex.named_captures(regex, repository_full_url) do

      {repository_owner, repository_name}

    else

      _ ->
        repository_full_url

    end

  end

  def get_repository_owner_and_name_by_full_url(_), do: false


  # Вырезает из строки название репозитория и ссылку
  def splitter_repo_line(line, io_write \\ 1) do
    str =
      line
      |> String.replace("* ", "")
      |> String.replace("[", "")
      |> String.replace("]", "")
      |> String.replace("(", "~")
      |> String.replace(")", "")
      |> String.replace(" - ", "~")
      |> String.split("~")


      repo_name = Enum.fetch!(str, 0)
      repo_link = Enum.fetch!(str, 1)
      # Repo desc? Описание режется с огрехами
      # repo_desc = Enum.fetch!(str, 2)

      if io_write == 1, do: IO.inspect(repo_name, label: "Repository")

    # Repo desc?
    {repo_name, repo_link}
  end

  # Вырезает из строки описание со всеми сслками
  def splitter_repo_desc(line) do
    str =
      line
      |> String.replace("* ", "")
      |> String.replace(" - ", "~")
      |> String.split("~")

    repo_desc = Enum.fetch!(str, 1)

    # Жуткий но вынужденный костыль в виде перевода markdown в HTML
    markdown_cat = Earmark.as_html!(repo_desc)

    # После преобразования в HTML подставляются теги <p> - они не нужны
    markdown_cat
    |> String.replace("<p>", "")
    |> String.replace("</p>", "")
    |> String.replace("\n", "")


    # Repo desc?
    # {repo_name, repo_link, repo_desc}
  end

  def get_category_name(array) do
    array
    |> hd()
    |> String.trim()
  end

  def get_category_description(array) do
    array
    |> tl()
    |> hd()
    |> String.trim("*")
  end

  # Преобразовать строку вида [Behaviours and Interfaces] в [behaviours-and-interfaces]
  def get_anchor_link(string) when is_binary(string)  do
    string
    |> String.downcase()
    |> String.replace(" / ", " ")
    |> String.replace("(", "")
    |> String.replace(")", "")
    |> String.replace(" ", "-")
  end

  def get_anchor_link(_), do: false

  def check_url(url) when is_binary(url) do
    pattern = "https://github.com/"
    result = String.starts_with?(url, pattern)
    result
  end

  def check_url(_), do: false



  def nil_filter(all_data) when is_list(all_data) or is_map(all_data) do
    Enum.filter(all_data, fn item ->
      if !is_nil(item) do
        item
      end
    end)
  end

  def nil_filter(_), do: false





  # Вторая функция для получения последнего коммита
  # вынимает из полученного json дату в формате iso
  def get_repository_last_commit_date_helper(json) when is_tuple(json) do
    {:ok, commit_data} = json
    if is_list(commit_data) && commit_data != [] do
      com = List.first(commit_data)
      last_commit_date = com["commit"]["committer"]["date"]
      {:ok, last_commit_date_r, 0} = DateTime.from_iso8601(last_commit_date)
      last_commit_date_r
    else
      false
    end
  end

  def get_repository_last_commit_date_helper(_), do: false

  # Третья функция  для получения последнего коммита - получает дату в iso
  # преобразует в unix, вычитает из unixtimestamp_today дату коммита,
  # получившееся число преобразует в дни
  def get_num_days_since_last_commit(last_commit_date_iso) do
    unix_date_commit = DateTime.to_unix(last_commit_date_iso)
    unix_today = DateTime.utc_now() |> DateTime.to_unix
    unix_today_minus_last = unix_today - unix_date_commit
    num_days_since_last_commit = unix_today_minus_last / 86400
    trunc(num_days_since_last_commit)
  end



  # Получить статус репозитария :actual || :outdate
  @spec get_repository_activity_status(any, any) :: :actual | :outdate
  def get_repository_activity_status(day_since_last_commit, outdate_day \\ 365) do
    if outdate_day >= day_since_last_commit, do: :actual, else: :outdate
  end

  # Получить минимум и максимум звезд для категории
  @spec get_min_max_stars_for_category(any) :: false | {any, any}
  def get_min_max_stars_for_category(data) when is_list(data) do
    all_repos = data

    if all_repos != [] do
      all_stars = Enum.map(all_repos, fn x ->
        x["repo_stars"]
      end)
      min_stars = Enum.min(all_stars)
      max_stars = Enum.max(all_stars)
      {min_stars, max_stars}
    else
      {:error, :error}
    end

  end

  def get_min_max_stars_for_category(_), do: false





  # Вспомогательные функции получения кеша из ets
  def get_all_info_in_ets_table() do
    all_info = GithubEtsCache.get_all_table_data()
    Enum.map(all_info, fn x ->
      {_, [category]} = x
      category
    end)
  end

  def get_one_category_from_ets_table(category) do
    repo_info = GithubEtsCache.get_one_table_data(category)
    [{_cat_name, repository}] = repo_info
    repository
  end



end
