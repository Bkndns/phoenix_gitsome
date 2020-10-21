defmodule GitsomeWeb.PageControllerTest do
  use GitsomeWeb.ConnCase

  alias Gitsome.Helper
  alias Gitsome.GithubEtsCache, as: Cache
  alias Gitsome.GitHub

  alias Gitsome.RepoSeeds

  def start_cache() do
    seeds = RepoSeeds.return_repo_seeds_data()
    # заполнить кэш
    Enum.each(seeds, fn x ->
      z = List.first(x)
      Cache.insert_data(z["category"], [z])
    end)
  end

  setup do
    start_cache()
  end

  describe "GET / 200 OK" do
    test "GET / 200", %{conn: conn} do
      conn = get(conn, "/")
      assert html_response(conn, 200) =~ "Debugging"
      assert html_response(conn, 200) =~ "eflame"
      assert html_response(conn, 200) =~ "Deployment"
      assert html_response(conn, 200) =~ "Documentation"
      assert html_response(conn, 200) =~ "Domain-specific language"
      assert html_response(conn, 200) =~ "GUI"
      assert html_response(conn, 200) =~ "scenic"
    end

    test "GET / 200 Get min_stars = 1000", %{conn: conn} do
      start_cache()
      conn = get(conn, "/?min_stars=1000")
      assert html_response(conn, 200) =~ "Deployment"
      assert html_response(conn, 200) =~ "GUI"
      assert html_response(conn, 200) =~ "scenic"
    end
  end

  
  describe "GET / 500 Error - Cache is Empty" do
    test "GET / 500 Cache is empty", %{conn: conn} do
      Cache.clear_all_table_data()
      conn = get(conn, "/")
      assert html_response(conn, 500) =~ "Render repository data error"
    end

    test "GET / 500 min_stars Cache is empty", %{conn: conn} do
      Cache.clear_all_table_data()
      conn = get(conn, "/?min_stars=1000")
      assert html_response(conn, 500) =~ "Show data min stars error. Data is empty. Please, check your cache data."
    end
  end


end
