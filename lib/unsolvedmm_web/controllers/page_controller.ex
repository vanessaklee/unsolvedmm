defmodule UnsolvedmmWeb.PageController do
  use UnsolvedmmWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
