defmodule Poloniex do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://poloniex.com"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 1_500

  adapter Tesla.Adapter.Hackney

  def name, do: "Poloniex"

  defp market_id(:xlm, :btc), do: "BTC_STR"
  defp market_id(_, _), do: nil

  defp market_bid_ask(market) do
    %Tesla.Env{status: 200, body: body} = get("/public?command=returnOrderBook&currencyPair=#{market}&depth=1")
    %{"asks" => [[ask_string, _ask_volume]|_],
      "bids" => [[bid_string, _bid_volume]|_]} = body
    {ask, _} = Float.parse(ask_string)
    {bid, _} = Float.parse(bid_string)
    %{ask: ask, bid: bid}
  end

  defp market_url(market) do
    "https://poloniex.com/exchange/##{market}"
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
