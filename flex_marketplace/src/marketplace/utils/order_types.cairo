use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
struct MakerOrder {
    is_order_ask: bool, // 1 = ask / 0 = bid
    signer: ContractAddress, // signer of the maker order
    collection: ContractAddress, // collection address
    price: u128,
    token_id: u256,
    amount: u128, // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
    strategy: ContractAddress, // strategy address for trade execution (e.g. StandardSaleForFixedPrice)
    currency: ContractAddress, // currency address
    nonce: u128, // order nonce (must be unique unless new maker order is meant to override existing one e.g. lower ask price)
    start_time: u64, // startTime in timestamp
    end_time: u64, // endTime in timestamp
    min_percentage_to_ask: u128, // slippage protection (9000 = 90% of the final price must return to ask)
    params: felt252,
}

#[derive(Copy, Drop, Serde)]
struct TakerOrder {
    is_order_ask: bool, // 1 = ask / 0 = bid
    taker: ContractAddress, // caller
    price: u128, // final price for the purchase
    token_id: u256,
    min_percentage_to_ask: u128, // slippage protection (9000 = 90% of the final price must return to ask)
    params: felt252,
}
