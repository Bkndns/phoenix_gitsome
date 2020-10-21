defmodule Gitsome.GithubTest do
  use ExUnit.Case, async: true

  # Тест основного модуля GitHub

  alias Gitsome.Helper
  alias Gitsome.GithubEtsCache, as: Cache
  alias Gitsome.GitHub

  alias Gitsome.RepoSeeds

  setup do
    # start_supervised({Gitsome.GithubEtsCache, []})
    # stop_supervised(Gitsome.GithubEtsCache)
    on_exit(fn -> Cache.clear_all_table_data() end)
  end

  describe "GitHub Functions" do

    test "request url" do
      assert GitHub.process_request_url("/repos/edgurgel/httpoison") == "https://api.github.com/repos/edgurgel/httpoison"
    end

    test "get README.md" do
      readme = GitHub.get_readme_content("edgurgel", "httpoison")
      {:ok, content} = readme
      assert content =~ "HTTP client for Elixir"
    end

    test "get Error repository README.md" do
      readme = GitHub.get_readme_content("edgurgelErr", "httpoisonErr")
      {:error, content} = readme
      assert content["message"] == "Not Found"
    end

    test "get all repository json info" do
      repo = GitHub.get_repository_json("edgurgel", "httpoison")
      {:ok, content} = repo
      assert content["homepage"] == "https://hex.pm/packages/httpoison"
      assert content["git_url"] == "git://github.com/edgurgel/httpoison.git"
      assert content["name"] == "httpoison"
    end

    test "test Redirect moved permanently get all repository json info" do
      repo = GitHub.get_repository_json("kbrw", "exos")
      {:ok, content} = repo
      assert content["id"] == 24095229
      assert content["name"] == "exos"
      assert content["full_name"] == "kbrw/exos"
    end

    test "get all repository json info Error" do
      repo = GitHub.get_repository_json("edgurgel00", "httpoison")
      {:ok, content} = repo
      assert content["message"] == "Not Found"
    end

    test "get repository last commit date response" do
      repo = GitHub.get_repository_last_commit_date("edgurgel", "httpoison")
      commit_iso_date = Helper.get_repository_last_commit_date_helper(repo)
      commit_num_days = Helper.get_num_days_since_last_commit(commit_iso_date)
      # assert content["message"] == "Not Found"
      assert commit_num_days >= 0
      refute commit_num_days == ""
    end

    @result_data_seed [
      %{
        "category" => "Deployment",
        "category_description" => "Installing and running your code automatically on other machines.",
        "id" => "deployment",
        "max_stars" => 1864,
        "min_stars" => 11,
        "repositories" => [
          %{
            "repo_activity_status" => "actual",
            "repo_description" => "Deployment for Elixir and Erlang",
            "repo_last_commit_date" => 221,
            "repo_link" => "https://github.com/boldpoker/edeliver",
            "repo_name" => "edeliver",
            "repo_stars" => 1864
          }
        ]
      },
      %{
        "category" => "Domain-specific language",
        "category_description" => "Specialized computer languages for a particular application domain.",
        "id" => "domain-specific-language",
        "max_stars" => 3332,
        "min_stars" => 23,
        "repositories" => [
          %{
            "repo_activity_status" => "actual",
            "repo_description" => "The GraphQL toolkit for Elixir",
            "repo_last_commit_date" => 7,
            "repo_link" => "https://github.com/absinthe-graphql/absinthe",
            "repo_name" => "Absinthe Graphql",
            "repo_stars" => 3332
          }
        ]
      },
      %{
        "category" => "GUI",
        "category_description" => "Libraries for writing Graphical User Interfaces.",
        "id" => "gui",
        "max_stars" => 1524,
        "min_stars" => 1524,
        "repositories" => [
          %{
            "repo_activity_status" => "actual",
            "repo_description" => "Core Scenic library",
            "repo_last_commit_date" => 22,
            "repo_link" => "https://github.com/boydm/scenic",
            "repo_name" => "scenic",
            "repo_stars" => 1500
          }
        ]
      }
    ]

    def start_cache() do
      seeds = RepoSeeds.return_repo_seeds_data()
      # заполнить кэш
      Enum.each(seeds, fn x ->
        z = List.first(x)
        Cache.insert_data(z["category"], [z])
      end)
    end

    test "get data by min stars 1000 stars from seed list" do
      start_cache()
      seeds = Helper.get_all_info_in_ets_table()
      {:ok, min_repos} = GitHub.show_data_by_min_stars(seeds, 1500)

      assert min_repos == @result_data_seed
    end

    test "render repository data frontend" do
      view_json = GitHub.render_repository_data(@result_data_seed)
      assert view_json == {:ok, @result_data_seed}
    end

    # test "parse awesome list" do
    #   see test/parsing/long_parsing_full_test.exs
    # end

    # test "parse each one category" do
    #   see test/parsing/long_parsing_one_category_test.exs
    # end

  end

end
