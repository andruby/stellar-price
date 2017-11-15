defmodule Gdax do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.gdax.com"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 1_500

  adapter Tesla.Adapter.Hackney

  def name, do: "Gdax"

  defp market_id(:btc, :eur), do: "BTC-EUR"
  defp market_id(:btc, :usd), do: "BTC-USD"
  defp market_id(:eth, :eur), do: "ETH-EUR"
  defp market_id(:eth, :usd), do: "ETH-USD"
  defp market_id(_, _), do: nil

  defp market_bid_ask(market) do
    %Tesla.Env{status: 200, body: body} = get("/products/#{market}/ticker")
    %{"ask" => ask_string, "bid" => bid_string} = body
    {ask, _} = Float.parse(ask_string)
    {bid, _} = Float.parse(bid_string)
    %{ask: ask, bid: bid}
  end

  defp market_url(market) do
    "https://www.gdax.com/trade/#{market}"
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
