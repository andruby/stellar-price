defmodule PriceyWeb.InfoChannel do
  use PriceyWeb, :channel

  def join("info:*", payload, socket) do
    {:ok, socket}
  end
end
