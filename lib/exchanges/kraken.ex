defmodule Kraken do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.kraken.com/0"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Elixir"}
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 1_500

  adapter Tesla.Adapter.Hackney

  def prices do
    %Tesla.Env{status: 200, body: body} = get("/public/Ticker?pair=XXLMXXBT")
    %{"a" => [ask_string, _ask_volume, _ask_lot_volume],
      "b" => [bid_string, _bid_volume, _bid_lot_volume]} = body["result"]["XXLMXXBT"]
    ask = String.to_float(ask_string)
    bid = String.to_float(bid_string)
    %{ask: ask, bid: bid}
  end

  def name do
    "Kraken"
  end

  def url do
    "https://www.kraken.com/"
  end
end
