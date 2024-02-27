%lang starknet

from starkware.cairo.common.uint256 import Uint256

struct MakerOrder {
    isOrderAsk: felt,  // 1 = ask / 0 = bid
    signer: felt,  // signer of the maker order
    collection: felt,  // collection address
    price: felt,
    tokenId: Uint256,
    amount: felt,  // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
    strategy: felt,  // strategy address for trade execution (e.g. StandardSaleForFixedPrice)
    currency: felt,  // currency address
    nonce: felt,  // order nonce (must be unique unless new maker order is meant to override existing one e.g. lower ask price)
    startTime: felt,  // startTime in timestamp
    endTime: felt,  // endTime in timestamp
    minPercentageToAsk: felt,  // slippage protection (9000 = 90% of the final price must return to ask)
    params: felt,  // additional parameters
}

struct TakerOrder {
    isOrderAsk: felt,  // 1 = ask / 0 = bid
    taker: felt,  // caller
    price: felt,  // final price for the purchase
    tokenId: Uint256,
    minPercentageToAsk: felt,  // slippage protection (9000 = 90% of the final price must return to ask)
    params: felt,  // additional parameters
}
