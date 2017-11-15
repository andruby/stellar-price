defmodule Bitstamp do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://www.bitstamp.net/api/v2"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 1_500

  adapter Tesla.Adapter.Hackney

  def name, do: "Bitstamp"

  def prices(:btc, :eur), do: market_bid_ask("btceur")
  def prices(:btc, :usd), do: market_bid_ask("btcusd")
  def prices(:eth, :eur), do: market_bid_ask("etheur")
  def prices(:eth, :usd), do: market_bid_ask("ethusd")
  def prices(_, _), do: nil

  defp market_bid_ask(market) do
    %Tesla.Env{status: 200, body: body} = get("/ticker/#{market}")
    %{"ask" => ask, "bid" => bid} = body
    %{ask: ask, bid: bid, exchange_name: name(), market_url: market_url(market)}
  end

  defp market_url(_) do
    "https://www.bitstamp.net/"
  end
end
