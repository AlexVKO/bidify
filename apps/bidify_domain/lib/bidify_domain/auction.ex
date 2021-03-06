defmodule Bidify.Domain.Auction do
  @moduledoc """
  Represents an auction, which is the aggregate root of the Auction aggregate.

  # Ubiquitous Language
  One can place a bid if:
  * He is not the owner of the auction
  * He is not the one currently winning the auction
  * The bid value is bigger than the current winning bid
  """

  alias Bidify.Domain.{Auction, Bid, Money}
  import Bidify.Utils.Comparable

  @type id :: term
  @type person_id :: term
  @type t :: %Auction{id: id, name: binary, closed: boolean, minimum_bid: Money.t, seller_id: person_id, bids: [Bid.t]}
  defstruct id: nil, name: nil, closed: false, minimum_bid: 0, seller_id: nil, bids: []

  @doc "Use Case: Create an auction"
  @spec create(person_id, binary, Money.t) :: t
  def create(_, "", _), do: {:error, "Name must not be empty"}
  def create(seller_id, name, %Money{} = minimum_bid) when seller_id != nil and name != nil do
    %Auction{seller_id: seller_id, minimum_bid: minimum_bid, name: name}
  end
  def create(_,_,_), do: {:error, "Invalid auction"}

  @doc "Use Case: Close an auction"
  @spec close(Auction.t) :: {:ok, Auction.t}
  def close(%Auction{closed: true}), do: {:error, "already closed"}
  def close(auction) do
    {:ok, %{auction | closed: true}}
  end

  @doc "Use Case: Place a bid"
  @spec place_bid(t, Bid.t) :: {:ok, t} | {:error, binary}
  def place_bid(auction, bid) do
    cond do
      auction.closed ->
        {:error, "auction is already closed"}

      bid.value.currency != auction.minimum_bid.currency ->
        {:error, "incorrect currency"}

      minimum_bid_value(auction) |> bt(bid.value) ->
        {:error, "bid value is not enough"}

      winning_bidder_id(auction) == bid.bidder_id ->
        {:error, "cannot bid on auction when winning already"}

      auction.seller_id == bid.bidder_id ->
        {:error, "cannot bid on own auction"}

      true ->
        {:ok, auction |> do_place_bid(bid)}
    end
  end

  @doc "Actually modify the auction to include the bid"
  @spec do_place_bid(t, Bid.t) :: t
  defp do_place_bid(auction, bid) do
    %{auction | bids: [bid | auction.bids]}
  end

  @doc "Gives the minimum value for the next bid"
  @spec minimum_bid_value(t) :: Money.t
  def minimum_bid_value(auction) do
    case winning_bid(auction) do
      %Bid{value: value} ->
        Money.add value, 1
      _ ->
        auction.minimum_bid
    end
  end

  @doc "Gives the id of the current winner"
  @spec winning_bidder_id(t) :: person_id | nil
  def winning_bidder_id(auction) do
    with %Bid{bidder_id: bidder_id} <- winning_bid(auction), do: bidder_id
  end

  @doc "Gives the currently winning bid"
  @spec winning_bid(t) :: Bid.t | nil
  def winning_bid(auction) do
    case auction.bids do
      [] ->
        nil
      bids ->
        bids |> Enum.max_by(&(&1.value.amount))
    end
  end

  @doc "Gives the reservation id of the current winning bid"
  @spec winning_reservation_id(t) :: term
  def winning_reservation_id(auction) do
    with %Bid{reservation_id: reservation_id} <- winning_bid(auction), do: reservation_id
  end
end
