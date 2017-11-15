defmodule Bittrex do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://bittrex.com/api/v1.1"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 1_500

  adapter Tesla.Adapter.Hackney

  def name, do: "Bittrex"

  defp market_id(:xlm, :btc), do: "BTC-XLM"
  defp market_id(:xlm, :eth), do: "ETH-XLM"
  defp market_id(_, _), do: nil

  defp market_bid_ask(market) do
    %Tesla.Env{status: 200, body: body} = get("/public/getticker?market=#{market}")
    %{"Ask" => ask, "Bid" => bid} = body["result"]
    %{ask: ask, bid: bid}
  end

  defp market_url(market) do
    "https://bittrex.com/Market/Index?MarketName=#{market}"
  end

  def price([base_currency, quote_currency]) do
    case market_id(base_currency, quote_currency) do
      nil -> nil
      market ->
        market_bid_ask(market)
        |> Map.merge(%{base_currency: base_currency, quote_currency: quote_currency, exchange_name: name(), market_url: market_url(market)})
    end
  end
end
