defmodule Bittrex do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://bittrex.com/api/v1.1"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 1_500

  adapter Tesla.Adapter.Hackney

  def name, do: "Bittrex"

  def prices(:xlm, :btc), do: market_bid_ask("BTC-XLM")
  def prices(:xlm, :eth), do: market_bid_ask("ETH-XLM")
  def prices(_, _), do: nil

  defp market_bid_ask(market) do
    %Tesla.Env{status: 200, body: body} = get("/public/getticker?market=#{market}")
    %{"Ask" => ask, "Bid" => bid} = body["result"]
    %{ask: ask, bid: bid, exchange_name: name(), market_url: market_url(market)}
  end

  defp market_url(market) do
    "https://bittrex.com/Market/Index?MarketName=#{market}"
  end
end
