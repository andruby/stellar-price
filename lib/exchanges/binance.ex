defmodule Binance do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.binance.com"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 1_500

  adapter Tesla.Adapter.Hackney

  def name, do: "Binance"

  defp market_id(:xlm, :btc), do: "XLMBTC"
  defp market_id(:xlm, :eth), do: "XLMETH"
  defp market_id(_, _), do: nil

  defp market_bid_ask(market) do
    %Tesla.Env{status: 200, body: body} = get("/api/v1/ticker/24hr?symbol=#{market}")
    %{"askPrice" => ask_string,
      "bidPrice" => bid_string} = body
    {ask, _} = Float.parse(ask_string)
    {bid, _} = Float.parse(bid_string)
    %{ask: ask, bid: bid}
  end

  defp market_url(market) do
    url_symbol = case market do
      "XLMBTC" -> "XLM_BTC"
      "XLMETH" -> "XLM_ETH"
    end
    "https://www.binance.com/trade.html?symbol=#{url_symbol}&ref=16537957"
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
