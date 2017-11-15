defmodule Gdax do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.gdax.com"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 1_500

  adapter Tesla.Adapter.Hackney

  def name, do: "Gdax"

  def prices(:btc, :eur), do: market_bid_ask("BTC-EUR")
  def prices(:btc, :usd), do: market_bid_ask("BTC-USD")
  def prices(:eth, :eur), do: market_bid_ask("ETH-EUR")
  def prices(:eth, :usd), do: market_bid_ask("ETH-USD")
  def prices(_, _), do: nil

  defp market_bid_ask(market) do
    %Tesla.Env{status: 200, body: body} = get("/products/#{market}/ticker")
    %{"ask" => ask, "bid" => bid} = body
    %{ask: ask, bid: bid, exchange_name: name(), market_url: market_url(market)}
  end

  defp market_url(market) do
    "https://www.gdax.com/trade/#{market}"
  end
end
