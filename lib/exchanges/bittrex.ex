defmodule Bittrex do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://bittrex.com/api/v1.1"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON

  adapter Tesla.Adapter.Hackney

  def prices do
    %Tesla.Env{status: 200, body: body} = get("/public/getticker?market=BTC-XLM")
    %{"Ask" => ask, "Bid" => bid} = body["result"]
    %{ask: ask, bid: bid}
  end
end
