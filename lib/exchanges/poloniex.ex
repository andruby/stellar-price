defmodule Poloniex do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://poloniex.com"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 1_500

  adapter Tesla.Adapter.Hackney

  def name, do: "Poloniex"

  def prices(:xlm, :btc), do: market_bid_ask("BTC_STR")
  def prices(_, _), do: nil

  defp market_bid_ask(market) do
    %Tesla.Env{status: 200, body: body} = get("/public?command=returnOrderBook&currencyPair=#{market}&depth=1")
    %{"asks" => [[ask_string, _ask_volume]|_],
      "bids" => [[bid_string, _bid_volume]|_]} = body
    ask = String.to_float(ask_string)
    bid = String.to_float(bid_string)
    %{ask: ask, bid: bid, exchange_name: name(), market_url: market_url(market)}
  end

  defp market_url(market) do
    "https://poloniex.com/exchange/##{market}"
  end
end
