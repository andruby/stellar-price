defmodule Pricey.Fetcher do
  use Task, restart: :permanent

  @exchanges [Poloniex, Bittrex, Kraken]

  def start_link do
    Task.start_link(__MODULE__, :run, [])
  end

  def run do
    spawn(&fetch/0)
    # We might want to use messages passing here with Process.send_after
    Process.sleep(2_000)
    run()
  end

  def fetch do
    prices = async_prices()
    lowest_ask = Enum.sort_by(prices, fn(%{ask: ask}) -> ask end) |> List.first
    highest_bid = Enum.sort_by(prices, fn(%{bid: bid}) -> bid end) |> List.last
    IO.puts "Lowest ask: #{lowest_ask[:ask]} by #{lowest_ask[:exchange]}"
    IO.puts "Highest bid: #{highest_bid[:bid]} by #{highest_bid[:exchange]}"
  end

  def async_prices do
    Enum.map(@exchanges, fn(exchange) ->
      Task.async(fn ->
        apply(exchange, :prices, [])
        |> Map.put(:exchange, exchange)
      end)
    end)
    |> Enum.map(&Task.await/1)
  end
end
