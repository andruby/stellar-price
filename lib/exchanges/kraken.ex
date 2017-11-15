defmodule Kraken do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.kraken.com/0"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 1_500 # We often need more than 1.5s :-/

  adapter Tesla.Adapter.Hackney

  def name, do: "Kraken"

  defp market_id(:xlm, :btc), do: "XXLMXXBT"
  defp market_id(:eth, :eur), do: "XETHZEUR"
  defp market_id(:btc, :eur), do: "XXBTZEUR"
  defp market_id(:eth, :usd), do: "XETHZUSD"
  defp market_id(:btc, :usd), do: "XXBTZUSD"
  defp market_id(_, _), do: nil

  defp market_bid_ask(market) do
    %Tesla.Env{status: 200, body: body} = get("/public/Ticker?pair=#{market}")
    %{"a" => [ask_string, _ask_volume, _ask_lot_volume],
      "b" => [bid_string, _bid_volume, _bid_lot_volume]} = body["result"][market]
    ask = String.to_float(ask_string)
    bid = String.to_float(bid_string)
    %{ask: ask, bid: bid}
  end

  defp market_url(_) do
    "https://www.kraken.com/"
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
