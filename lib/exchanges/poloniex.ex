defmodule Poloniex do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://poloniex.com"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON

  adapter Tesla.Adapter.Hackney

  def prices do
    %Tesla.Env{status: 200, body: body} = get("/public?command=returnOrderBook&currencyPair=BTC_STR&depth=1")
    %{"asks" => [[ask_string, _ask_volume]|_],
      "bids" => [[bid_string, _bid_volume]|_]} = body
    ask = String.to_float(ask_string)
    bid = String.to_float(bid_string)
    %{ask: ask, bid: bid}
  end
end
