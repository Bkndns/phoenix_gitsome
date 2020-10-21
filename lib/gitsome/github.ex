defmodule Gitsome.GitHub do
  use HTTPoison.Base
  require Logger

  import Gitsome.Helper

  alias Gitsome.GithubEtsCache

  @github_basic_token Application.get_env(:gitsome, :git_hub_key)


  '''
  alias Gitsome.GitHub
  alias Gitsome.GithubEtsCache
  GithubEtsCache.table_exist?
  GitHub.prepare_each_one

  GitHub.get_readme_content("edgurgel", "httpoison")
  GitHub.get_repository_json("edgurgel", "httpoison")

  GitHub.get_repository_json("marcelotto", "jsonld-ex")
  '''


  ### ### ### ### ### ### ### ###

  def process_request_url(url) do
    "https://api.github.com" <> url
  end

  def process_request_headers(headers) when is_map(headers) do
    Enum.into(headers, [])
  end

  def process_request_headers(headers) do
    headerso = ["Content-Type": "application/json", "Authorization": "token #{@github_basic_token}"]
    Keyword.merge(headers, headerso)
  end

  ### ### ### ### ### ### ### ###



  # Получаем всё содержимое README.md репозитория
  def get_readme_content(owner, repository_name) do
    a = get!("/repos/#{owner}/#{repository_name}/readme", [], stream_to: self(), async: :once, hackney: [pool: :default])

    {%HTTPoison.AsyncResponse{id: _id}, body} = async_response(a)

    json = Jason.decode!(body)
    # IO.inspect(json)

    if Map.has_key?(json, "content") do
      readme = Base.decode64!(json["content"], ignore: :whitespace)
      # IO.inspect(readme)
      {:ok, readme}
    else
      {:error, json}
    end
  end





  # Запрос информации о репозитории [get_repository_json("edgurgel", "httpoison")]
  def get_repository_json(owner, repository_name) do
    # headers = ["Content-Type": "application/json", "Authorization": "token #{@github_basic_token}"]

    json_content = get!(
      "/repos/#{owner}/#{repository_name}",
      [],
      stream_to: self(),
      async: :once,
      follow_redirect: true,
      max_redirect: 5,
      hackney: [{:force_redirect, true}, {:pool, :default}]
    )

    {%HTTPoison.AsyncResponse{id: _id}, body} = async_response(json_content)

    # IO.inspect(body)

    json = Jason.decode!(body)
    {:ok, json}


  end

  # Для AsyncRedirect - Если репозиторий Moved Permanently - [get_repository_json("https://api.github.com/repositories/24095229")]
  def get_repository_json(redirect_url) do
    headers = ["Content-Type": "application/json", "Authorization": "token #{@github_basic_token}"]

    json_content = HTTPoison.get!(
      redirect_url,
      headers,
      stream_to: self(),
      async: :once,
      follow_redirect: true,
      max_redirect: 5,
      hackney: [{:force_redirect, true}, {:pool, :default}]
    )

    {%HTTPoison.AsyncResponse{id: _id}, body} = async_response(json_content)

    # json = Jason.decode!(body)
    body
  end





  # Первая функция для получения последнего коммита
  # делает запрос и возвращает json ответ
  def get_repository_last_commit_date(owner, repository_name) do
    headers = ["Accept:": "application/vnd.github.v3+json"]

    json_content = get!(
      "/repos/#{owner}/#{repository_name}/commits?per_page=1",
      headers,
      stream_to: self(),
      async: :once,
      follow_redirect: true,
      max_redirect: 5,
      hackney: [{:force_redirect, true}, {:pool, :default}]
    )

    {%HTTPoison.AsyncResponse{id: _id}, body} = async_response(json_content)
    json = Jason.decode!(body)
    # IO.inspect(json)

    # get_repository_last_commit_date_helper(json)
    {:ok, json}

  end

  # Первая функция для получения последнего коммита
  # Вызывается если происходит редирект в случае "message" => "Moved Permanently"
  def get_repository_last_commit_date(redirect_url) do
    headers = ["Accept:": "application/vnd.github.v3+json", "Content-Type": "application/json", "Authorization": "token #{@github_basic_token}"]

    json_content = get!(
      redirect_url,
      headers,
      stream_to: self(),
      async: :once,
      follow_redirect: true,
      max_redirect: 5,
      hackney: [{:force_redirect, true}, {:pool, :default}]
    )

    {%HTTPoison.AsyncResponse{id: _id}, body} = async_response(json_content, [], 1)

    # json = Jason.decode!(body)
    body
  end





  # Основная функция обработки запросов, HTTParty
  def async_response(resp, body \\ [], get_commits \\ 0) do

    response_id = resp.id

    {resp, bod} =

      receive do
        %HTTPoison.AsyncRedirect{id: ^response_id, to: to, headers: _headers} ->
          # IO.inspect(headers)
          # IO.inspect(to, label: "Redirect to")

          # В зависимости от какого запроса приходит редирект repository || commit
          body = if get_commits == 0 do
            get_repository_json(to)
          else
            get_repository_last_commit_date(to)
          end

          stream_next(resp)

          {resp, body}

        %HTTPoison.AsyncStatus{id: ^response_id, code: _status_code} ->
          # IO.inspect(status_code)
          stream_next(resp)
          async_response(resp, body)
        %HTTPoison.AsyncHeaders{id: ^response_id, headers: _headers} ->
          # IO.inspect(headers)
          stream_next(resp)
          async_response(resp, body)
        %HTTPoison.AsyncChunk{id: ^response_id, chunk: chunk} ->
          # IO.inspect(chunk)
          stream_next(resp)
          async_response(resp, body ++ [chunk])
        %HTTPoison.AsyncEnd{id: ^response_id} ->
          :ok

        {resp, body}
      end

    {resp, bod}


  end





  # Прячем категории у которых звезд >= min_start
  defp get_data_by_min_stars(data, min_start) do
    Enum.map(data, fn x ->
      # category = List.first(x)
      category = (x)
      if category["max_stars"] >= min_start do
        %{
          "category" => category["category"],
          "category_description" => category["category_description"],
          "id" => category["id"],
          "max_stars" => category["max_stars"],
          "min_stars" => category["min_stars"],
          "repositories" => get_repos_by_min_stars(category, min_start)
        }
      end
    end)
    # returner
  end

  # Прячем репозитории у которых звезд >= min_start
  defp get_repos_by_min_stars(data_repos, min_start) do
    repo = Enum.map(data_repos["repositories"], fn repo ->
      if repo["repo_stars"] >= min_start do
        repo
      end
    end)
    return = nil_filter(repo)
    return
  end

  # Выводим данные по запросу min_stars во фронтенд
  def show_data_by_min_stars(data_repos, min_start \\ 0) do
    min_stars = cond do
      is_bitstring(min_start) -> String.to_integer(min_start)
      is_integer(min_start) -> min_start
    end

    if (data_repos != nil) && (data_repos != []) do
      all_data = get_data_by_min_stars(data_repos, min_stars)
      all_min_stars = nil_filter(all_data)
      {:ok, all_min_stars}
    else
      Logger.error("Show data min stars error. Data is empty. Please, check your cache data.")
      {:error, "Show data min stars error. Data is empty. Please, check your cache data."}
    end
  end





  # Для вывода репозиториев во фронтенд
  def render_repository_data(data) do
    if (data != nil) && (data != []) do
      final_map = Enum.map(data, fn x ->
        category = x
        %{
          "category" => category["category"],
          "category_description" => category["category_description"],
          "id" => category["id"],
          "max_stars" => category["max_stars"],
          "min_stars" => category["min_stars"],
          "repositories" => get_repos_for_category(category)
        }
      end)
      {:ok, final_map}
    else
      Logger.error("Render repository data error. Data cache is empty. Check your cache data or Parse data now.")
      {:error, "Render repository data error. Data cache is empty. Check your cache data or Parse data now."}
    end
  end

  # Прячем репозитории у которых звезд >= min_start
  defp get_repos_for_category(data_repos) do
    repo = Enum.map(data_repos["repositories"], fn repo ->
        repo
    end)
    return = nil_filter(repo)
    return
  end



  '''
  ---------------------------------------------
  Parse
  ---------------------------------------------
  '''



  # Основная функция запуска парсинга
  def parse_awesome_list() do

    read_content = get_readme_content("h4cc", "awesome-elixir")

    # start = System.monotonic_time(:millisecond)

    with {:ok, readme} <- read_content do

      readme
      |> String.split("##")
      |> tl()

      |> Enum.map(fn item ->
        # Мультипоточность?
        Task.start(fn -> prepare_each_one(item) end)
        # spawn(fn -> prepare_each_one(item) end)
      end)
      |> nil_filter() # Чтобы не возвращались пустые категории в которых нет репозиториев

    end

    # stop = System.monotonic_time(:millisecond)

    # time = (stop - start) / 1000
    # IO.puts("time: #{time}")
  end
  ###############################################



  # Обработка каждого элемента
  def prepare_each_one(scheme) do

    # Приходит категория строкой и \n внутри. Нужно обработать
    scheme = String.split(scheme, "\n")

    category_name = get_category_name(scheme)

    category_desc = get_category_description(scheme)

    anchor_link = get_anchor_link(category_name)


    aster_filter = Enum.filter(scheme, fn x -> String.starts_with?(x, "*") end)

    aster_tail = tl(aster_filter)

    repo_map = Enum.map(aster_tail, fn x ->

      {name, link} = splitter_repo_line(x)

      awesome_desc = splitter_repo_desc(x)

      # Проверка url на github.com не [https://www.gigalixir.com, https://bitbucket.org]
      if check_url(link) do

        {repo_owner, repo_name} = get_repository_owner_and_name_by_full_url(link)

        repo_data = get_repository_json(repo_owner, repo_name)

        # Репозиторий может вернуть данные или сообщение об ошибке
        repo_stars = case repo_data do
          {:ok, %{"stargazers_count" => repo_stars}} -> repo_stars
          {:ok, %{"documentation_url" => _doc_url, "message" => message}} -> message
          _ -> :error
        end


        # Если repo_stars не число, значит вернулось сообщение об ошибке, такой репозиторий не берем
        if is_integer(repo_stars) do

          # Сколько дней прошло с последнего коммита
          repo_last_commit_date =
            get_repository_last_commit_date(repo_owner, repo_name)
            |> get_repository_last_commit_date_helper()
            |> get_num_days_since_last_commit()

          # Статус репозитория - активен или заброшен
          repo_activity_status = get_repository_activity_status(repo_last_commit_date)

          %{
              "repo_name" => name,
              "repo_link" => link,
              "repo_description" => awesome_desc, #repo_desc,
              "repo_stars" => repo_stars,
              "repo_last_commit_date" => repo_last_commit_date,
              "repo_activity_status" => Atom.to_string(repo_activity_status)
          }

        end

      end

    end)

    # Отфильтруем ссылки которые не ведут на github и возвращают nil
    all_repositories_in_category = nil_filter(repo_map)


    # Минимальное и максимальное кол-во звезд на категорию для фильтрации
    {min_cat_stars, max_cat_stars} = get_min_max_stars_for_category(all_repositories_in_category)

    # :error вернется в случае если ссылка репозитория была не на GitHub.
    if max_cat_stars != :error do
      return_item = [
        %{
          "category" => category_name,
          "category_description" => category_desc,
          "id" => anchor_link,
          "min_stars" => min_cat_stars,
          "max_stars" => max_cat_stars,
          "repositories" => all_repositories_in_category
        }
      ]

      # INSERT IN TABLE
      GithubEtsCache.insert_data(category_name, return_item)

      return_item
    end


  end



end
