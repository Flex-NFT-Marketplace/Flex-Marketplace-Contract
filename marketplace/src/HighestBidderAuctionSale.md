# This is an explainer doc for the Highest Bidder Auction Sale Strategy

The contract makes possible an auction where the highest valid bid during the period of auction will be the winning bid.

## Addition

### Validate Highest Bid

The logic here is to check if the new/incoming bid (`taker_bid` or `maker_bid`) is the highest bid, by comparing the prices, in both the `can_execute_taker_ask` and `can_execute_taker_bid`.

#### Bid Acceptance

If the bid is higher than the current highest bid i.e the valid bid, the auction will proceed with that bid.

#### Winning Bid Amount

The value that is returned here is either the `taker_bid.price` or `maker_bid.price` which in this case includes the winning bid price.
