defmodule PriceyWeb.InfoChannel do
  use PriceyWeb, :channel

  def join("info:*", _payload, socket) do
    {:ok, socket}
  end
end
