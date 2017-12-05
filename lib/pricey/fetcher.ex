defmodule Pricey.Fetcher do
  use Task, restart: :permanent

  # @exchanges [Poloniex, Bittrex, Kraken, Gdax, Bitstamp]
  @exchanges [Poloniex, Bittrex, Kraken, Gdax]
  @base_pairs [
    [:eth, :eur],
    [:btc, :eur],
    [:eth, :usd],
    [:btc, :usd],
    [:xlm, :btc],
    [:xlm, :eth],
  ]

  @indirect_pairs %{
    [:xlm, :eur] => [
      [[:xlm, :btc], [:btc, :eur]],
      [[:xlm, :eth], [:eth, :eur]],
    ],
    [:xlm, :usd] => [
      [[:xlm, :btc], [:btc, :usd]],
      [[:xlm, :eth], [:eth, :usd]],
    ],
  }

  def base_pairs do
    @base_pairs
  end

  def start_link do
    Task.start_link(__MODULE__, :run, [])
  end

  def run do
    spawn(&fetch/0)
    # We might want to use messages passing here with Process.send_after
    Process.sleep(2_000)
    run()
  end

  defp broadcast(base_currency, quote_currency, trade_direction, best_prices) do
    best_prices_with_direction = best_prices
    |> Enum.map(fn(best_price) -> Map.put(best_price, :trade_direction, trade_direction) end)
    PriceyWeb.Endpoint.broadcast "info:#{trade_direction}:#{base_currency}:#{quote_currency}", "tick", %{route: best_prices_with_direction}
  end

  def fetch do
    # Part 1: direct pairs
    prices = @base_pairs
    |> Enum.zip(pmap(@base_pairs, fn([base_currency, quote_currency]) ->
      price = best_price(base_currency, quote_currency)
      broadcast(base_currency, quote_currency, "buy", [price[:lowest_ask]])
      broadcast(base_currency, quote_currency, "sell", [price[:highest_bid]])
      price
    end))
    |> Enum.into(%{})

    # Part 2: indirect pairs
    @indirect_pairs
    |> Enum.each(fn({[indirect_base_currency, indirect_quote_currency], routes}) ->
      # Buy route
      buy_routes = Enum.map(routes, fn(route) ->
        Enum.map(route, fn([base_currency, quote_currency]) ->
          prices[[base_currency, quote_currency]][:lowest_ask]
        end)
        |> Enum.reverse # Buying must start with the right pair (first eur->btc, then btc->xlm)
      end)
      optimal_buy_route = Enum.sort_by(buy_routes, fn(route) ->
        Enum.reduce(route, 1.0, &(&1[:ask] * &2))
      end) |> List.first
      broadcast(indirect_base_currency, indirect_quote_currency, "buy", optimal_buy_route)
      # Sell route
      sell_routes = Enum.map(routes, fn(route) ->
        Enum.map(route, fn([base_currency, quote_currency]) ->
          prices[[base_currency, quote_currency]][:highest_bid]
        end)
      end)
      optimal_sell_route = Enum.sort_by(sell_routes, fn(route) ->
        Enum.reduce(route, 1.0, &(&1[:bid] * &2))
      end) |> List.last
      broadcast(indirect_base_currency, indirect_quote_currency, "sell", optimal_sell_route)
    end)
  end

  defp best_price(base_currency, quote_currency) do
    prices = @exchanges
    |> pmap(fn(exchange) ->
      try do
        apply(exchange, :price, [[base_currency, quote_currency]])
      rescue
        _ in Elixir.Tesla.Middleware.Timeout -> nil
      end
    end)
    |> Enum.reject(&(is_nil(&1)))

    for price <- prices do
      PriceyWeb.Endpoint.broadcast "info:all", "tick", price
    end

    lowest_ask = Enum.sort_by(prices, fn(%{ask: ask}) -> ask end) |> List.first
    highest_bid = Enum.sort_by(prices, fn(%{bid: bid}) -> bid end) |> List.last
    %{lowest_ask: lowest_ask, highest_bid: highest_bid}
  end

  defp pmap(collection, func) do
    collection
    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
    |> Enum.map(&Task.await/1)
  end
end
