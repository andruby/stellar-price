defmodule PriceyWeb.PageController do
  use PriceyWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
