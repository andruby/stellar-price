defmodule Bitstamp do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://www.bitstamp.net/api/v2"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 1_500

  adapter Tesla.Adapter.Hackney

  def name, do: "Bitstamp"

  defp market_id(:btc, :eur), do: "btceur"
  defp market_id(:btc, :usd), do: "btcusd"
  defp market_id(:eth, :eur), do: "etheur"
  defp market_id(:eth, :usd), do: "ethusd"
  defp market_id(_, _), do: nil

  defp market_bid_ask(market) do
    %Tesla.Env{status: 200, body: body} = get("/ticker/#{market}")
    %{"ask" => ask, "bid" => bid} = body
    %{ask: ask, bid: bid}
  end

  defp market_url(_) do
    "https://www.bitstamp.net/"
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
