defmodule Bidify.Web.BidController do
  use Bidify.Web.Web, :controller

  def create(conn, %{"auction_id" => auction_id, "bid" => %{"amount" => amount}}) do
    {amount, _} = Integer.parse(amount)
    {auction_id, _} = Integer.parse(auction_id)
    value = %Bidify.Domain.Money{amount: amount}

    config = %Bidify.Domain.AuctionService.Config{
      auction_repository: Bidify.Web.AuctionRepository,
      charging_service: Bidify.Web.ChargingService
    }

    current_user = Bidify.Web.Session.current_user(conn)
    result = Bidify.Domain.AuctionService.place_bid(config, auction_id, current_user.id, value)
    IO.puts(inspect(result))
    case result do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Thanks for the bid")
        |> redirect(to: auction_path(conn, :show, auction_id))
      {:error, err} ->
        conn
        |> put_flash(:error, "Error: #{inspect(err)}")
        |> redirect(to: auction_path(conn, :show, auction_id))
    end
  end
end
