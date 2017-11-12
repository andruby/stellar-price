defmodule PriceyWeb.InfoChannel do
  use PriceyWeb, :channel

  def join("info:" <> subtopic, _payload, socket) do
    IO.puts "Joined subtopic: #{subtopic}"
    {:ok, socket}
  end
end
