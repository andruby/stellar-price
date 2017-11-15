defmodule Kraken do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.kraken.com/0"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 1_500 # We often need more than 1.5s :-/

  adapter Tesla.Adapter.Hackney

  def name, do: "Kraken"

  def prices(:xlm, :btc), do: market_bid_ask("XXLMXXBT")
  def prices(:eth, :eur), do: market_bid_ask("XETHZEUR")
  def prices(:btc, :eur), do: market_bid_ask("XXBTZEUR")
  def prices(:eth, :usd), do: market_bid_ask("XETHZUSD")
  def prices(:btc, :usd), do: market_bid_ask("XXBTZUSD")
  def prices(_, _), do: nil

  defp market_bid_ask(market) do
    %Tesla.Env{status: 200, body: body} = get("/public/Ticker?pair=#{market}")
    %{"a" => [ask_string, _ask_volume, _ask_lot_volume],
      "b" => [bid_string, _bid_volume, _bid_lot_volume]} = body["result"][market]
    ask = String.to_float(ask_string)
    bid = String.to_float(bid_string)
    %{ask: ask, bid: bid, exchange_name: name(), market_url: market_url(market)}
  end

  defp market_url(_) do
    "https://www.kraken.com/"
  end
end
