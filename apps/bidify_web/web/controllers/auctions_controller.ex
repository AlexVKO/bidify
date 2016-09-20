defmodule Bidify.Web.AuctionController do
  use Bidify.Web.Web, :controller

  def index(conn, _params) do
    auctions = Bidify.Web.Repo.all Bidify.Web.Auction
    render conn, "index.html", auctions: auctions
  end

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"auction" => auction_params}) do
    {minimum_bid_amount, _} = auction_params["minimum_bid_amount"] |> Integer.parse
    minimum_bid = Bidify.Domain.Money.new(minimum_bid_amount)
    name = auction_params["name"]
    config = %Bidify.Domain.AuctionService.Config{
      auction_repository: Bidify.Web.AuctionRepository,
      charging_service: Bidify.Web.ChargingService
    }
    current_user = Bidify.Web.Session.current_user(conn)
    case Bidify.Domain.AuctionService.create_auction(config, current_user.id, name, minimum_bid) do
      {:ok, auction} ->
        conn
        |> put_flash(:info, "Auction placed")
        |> redirect(to: "/")
      _ ->
        conn
        |> put_flash(:error, "Something wrong dude")
        |> render("new.html")
    end
  end

  def show(conn, %{"id" => auction_id}) do
    {auction_id, _} = Integer.parse(auction_id)
    {:ok, auction} = Bidify.Web.AuctionRepository.find(auction_id)
    winning_bid = Bidify.Domain.Auction.winning_bid(auction)
    IO.puts(inspect(auction))
    render conn, "show.html", auction: auction, winning_bid: winning_bid
  end
end
