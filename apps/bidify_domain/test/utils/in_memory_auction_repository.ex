defmodule InMemoryAuctionRepository do
  @behaviour Bidify.Domain.AuctionRepository
  use Bidify.Utils.InMemoryEntityRepository
end
