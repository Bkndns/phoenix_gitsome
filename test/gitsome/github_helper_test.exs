defmodule Gitsome.HelperTest do
  use ExUnit.Case, async: true

  alias Gitsome.Helper
  alias Gitsome.GithubEtsCache



  describe "Функции из цельной ссылки получить владельца и название репозитория" do
    # setup [:my_hook]
    @good_url "https://github.com/edgurgel/httpoison"
    @bad_url1 "https://github.com/edgurgel"
    @bad_url2 "https://github.com/"
    @bad_url3 "https://github"

    test "Check url is valid - return owner and repo name Good" do
      assert Helper.get_repository_owner_and_name_by_full_url(@good_url) == {"edgurgel", "httpoison"}
    end

    test "Check url is valid - return owner and repo name" do
      assert Helper.get_repository_owner_and_name_by_full_url(@bad_url1) == @bad_url1
      assert Helper.get_repository_owner_and_name_by_full_url(@bad_url2) == "https://github.com/"
      assert Helper.get_repository_owner_and_name_by_full_url(@bad_url3) == @bad_url3
      refute Helper.get_repository_owner_and_name_by_full_url(@bad_url1) == @good_url
      assert Helper.get_repository_owner_and_name_by_full_url("") == ""
      refute Helper.get_repository_owner_and_name_by_full_url([]) == true
      refute Helper.get_repository_owner_and_name_by_full_url({}) == true
      refute Helper.get_repository_owner_and_name_by_full_url(%{}) == true
      refute Helper.get_repository_owner_and_name_by_full_url(:joht) == true
    end
  end



  describe "Функции получения различной информации из спаршенного Readme (категория, описание, ссылка)" do

    # Такая строка приходит на обработку. Это одна категория
    @scheme [" Actors", "*Libraries and tools for working with actors and such.*", "",
      "* [phoenix](https://github.com/phoenixframework/phoenix) - Elixir Web Framework targeting full-featured, fault tolerant applications with realtime functionality.",
      "* [dflow](https://github.com/dalmatinerdb/dflow) - Pipelined flow processing engine.",
      "* [exactor](https://github.com/sasa1977/exactor) - Helpers for easier implementation of actors in Elixir.",
      "* [exos](https://github.com/awetzel/exos) - A Port Wrapper which forwards cast and call to a linked Port.",
      "* [sbroker](https://github.com/fishcakez/sbroker) - Sojourn-time based active queue management library.",
      "* [workex](https://github.com/sasa1977/workex) - Backpressure and flow control in EVM processes.",
      "* [workexErrrr](https://github.com/sasa19773232322ee/workex) - Backpressure and flow control in EVM processes.",
    "", ""]
    @one_line_repo "* [phoenix](https://github.com/phoenixframework/phoenix) - Elixir Web Framework targeting full-featured, fault tolerant applications with realtime functionality."


    test "Cut from string repo_name and repo_link" do
      assert Helper.splitter_repo_line(@one_line_repo, 0) == {"phoenix", "https://github.com/phoenixframework/phoenix"}
    end

    test "Cut from string category description" do
      assert Helper.splitter_repo_desc(@one_line_repo) == "Elixir Web Framework targeting full-featured, fault tolerant applications with realtime functionality."
    end

    test "Get category name from scheme list" do
      assert Helper.get_category_name(@scheme) == "Actors"
    end

    test "Get category description from scheme list" do
      assert Helper.get_category_description(@scheme) == "Libraries and tools for working with actors and such."
    end

    test "Get alias from category name" do
      assert Helper.get_anchor_link("Actors") == "actors"
      assert Helper.get_anchor_link("Behaviours and Interfaces") == "behaviours-and-interfaces"
      assert Helper.get_anchor_link("") == ""
      assert Helper.get_anchor_link(99) == false
      assert Helper.get_anchor_link([]) == false
      assert Helper.get_anchor_link(%{}) == false
      assert Helper.get_anchor_link({}) == false
    end

    test "Link start with https://github.com/" do
      assert Helper.check_url("https://github.com/phoenixframework/phoenix") == true
      assert Helper.check_url("github.com/phoenixframework/phoenix") == false
      assert Helper.check_url("test str") == false
      assert Helper.check_url("") == false
      assert Helper.check_url(8) == false
      assert Helper.check_url([]) == false
    end

    test "Nil Filter" do
      data = [nil, :cat, nil, "dog", nil, nil, :hotdog]
      assert Helper.nil_filter(data) == [:cat, "dog", :hotdog]
      assert Helper.nil_filter("") == false
      assert Helper.nil_filter({}) == false
      assert Helper.nil_filter(%{}) == []
      assert Helper.nil_filter([]) == []
    end


  end



  describe "Функции получения даты последнего комита, активности, звезд, ифнормации о репозитории" do
    test "Helper get date last commit from json" do
      json_content = {
        :ok,
        [
          %{
            "author" => %{
              "avatar_url" => "https://avatars1.githubusercontent.com/u/39219943?v=4",
              "html_url" => "https://github.com/Arp-G",
              "id" => 39219943,
              "login" => "Arp-G",
              "node_id" => "MDQ6VXNlcjM5MjE5OTQz",
              "type" => "User",
            },
            "commit" => %{
              "author" => %{
                "date" => "2020-10-19T08:27:25Z",
                "email" => "arpanghoshal3@gmail.com",
                "name" => "Arpan Ghoshal"
              },
              "comment_count" => 0,
              "committer" => %{
                "date" => "2020-10-19T08:27:25Z",
                "email" => "noreply@github.com",
                "name" => "GitHub"
              },
              "url" => "https://api.github.com/repos/h4cc/awesome-elixir/git/commits/454b7f3dcc567998ee3d5dbfd6fde537cf556924",
              "sha" => "454b7f3dcc567998ee3d5dbfd6fde537cf556924",
            }
          }
        ]
      }

      assert Helper.get_repository_last_commit_date_helper(json_content) == ~U[2020-10-19 08:27:25Z]
      assert Helper.get_repository_last_commit_date_helper([]) == false
      assert Helper.get_repository_last_commit_date_helper({:ok, []}) == false
      assert Helper.get_repository_last_commit_date_helper("") == false
    end

    test "Since date last commit date" do
      # ~U[2020-10-14T23:54:36Z] # Приходит в таком формате с Github
      # Не знаю как еще проверить дату, которая ожидается в определенном формате.
      unix_today = DateTime.utc_now() |> DateTime.to_unix
      {:ok, last2day_commit} = DateTime.from_unix(unix_today - 172800) # - 2 суток для теста
      assert Helper.get_num_days_since_last_commit(last2day_commit) == 2
      # refute Helper.get_num_days_since_last_commit(last2day_commit) == 10
    end

    test "Repository status actual or outdate" do
      assert Helper.get_repository_activity_status(150) == :actual
      assert Helper.get_repository_activity_status(150, 130) == :outdate
      assert Helper.get_repository_activity_status(365, 365) == :actual
      assert Helper.get_repository_activity_status(0) == :actual

      assert Helper.get_repository_activity_status([]) == :outdate
      assert Helper.get_repository_activity_status(%{}) == :outdate
      assert Helper.get_repository_activity_status("o") == :outdate
      assert Helper.get_repository_activity_status(:pong) == :outdate
    end

    test "Get min max stars for category" do
      all_repo = [
        %{"repo_stars" => 20},
        %{"repo_stars" => 21},
        %{"repo_stars" => 123},
        %{"repo_stars" => 3},
        %{"repo_stars" => 32},
        %{"repo_stars" => 4},
        %{"repo_stars" => 33},
        %{"repo_stars" => 555},
        %{"repo_stars" => 75},
        %{"repo_stars" => 12},
        %{"repo_stars" => 1}
      ]
      stars = Helper.get_min_max_stars_for_category(all_repo)
      assert stars == {1, 555} # {min_start, max_stars}

      assert Helper.get_min_max_stars_for_category([]) == {:error, :error}
      assert Helper.get_min_max_stars_for_category("") == false
      assert Helper.get_min_max_stars_for_category(:atom) == false

    end
  end



  describe "Функции получения данных из кеша" do

    setup do
      on_exit(fn -> Gitsome.GithubEtsCache.clear_all_table_data() end)
    end

    test "get_all_info_in_ets_table" do
      if Gitsome.GithubEtsCache.table_exist?() do

        data1 = [
          %{
            "category" => "Actors",
            "category_description" => "Actors something",
            "id" => "actors",
            "min_stars" => "1",
            "max_stars" => "666",
            "repositories" => %{}
          }
        ]

        final_data = [
          %{
            "category" => "Actors",
            "category_description" => "Actors something",
            "id" => "actors",
            "max_stars" => "666",
            "min_stars" => "1",
            "repositories" => %{}
          }
        ]

        Gitsome.GithubEtsCache.insert_data(:user1, data1)
        assert Helper.get_all_info_in_ets_table() == final_data
      end
    end

    test "get one category from ets table" do
      data = %{
          age: 25,
          car: "Tayota",
          gender: "female",
          lastname: "Ko",
          name: "K",
          phone: "iPhone 11"
      }
      GithubEtsCache.insert_data(:users2, %{name: "K", lastname: "Ko", age: 25, gender: "female", car: "Tayota", phone: "iPhone 11"})
      assert Helper.get_one_category_from_ets_table(:users2) == data
    end
  end



end
