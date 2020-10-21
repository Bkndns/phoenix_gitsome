defmodule GitsomeWeb.PageController do
  use GitsomeWeb, :controller

  alias Gitsome.GitHub
  alias Gitsome.Helper


  defp case_render_statement(conn, case_stt) do
    case case_stt do
      {:ok, content} -> render(conn, "index.html", github_content: content)
      {:error, error} -> conn
                          |> put_status(500)
                          |> put_view(GitsomeWeb.ErrorView)
                          |> render(:"500", %{error: error})
                          |> halt()
    end
  end


  # Если присутствует параметр "min_stars"
  def index(conn, %{"min_stars" => min_stars} = _params) do
    github_data = Helper.get_all_info_in_ets_table()
    show_content_with_stars_param = GitHub.show_data_by_min_stars(github_data, min_stars)
    case_render_statement(conn, show_content_with_stars_param)
  end

  def index(conn, _params) do
    github_data = Helper.get_all_info_in_ets_table()
    show_content = GitHub.render_repository_data(github_data)
    case_render_statement(conn, show_content)
  end
end
