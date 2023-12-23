use starknet::ContractAddress;
#[derive(Drop, Serde)]
struct MakerOrder {
    isOrderAsk: bool,
    signer: ContractAddress,
    collection: ContractAddress,
    price: u256,
    tokenId: u256,
    amount: u128,
    stategy: u256,
    currency: ContractAddress,
    nonce: u256,
    startTime: u64,
    endTime: u64,
    minPercentageToAsk: u128,
    params: Span<felt252>,
}

#[derive(Drop, Serde)]
struct TakerOrder {
    isOrderAsk: bool,
    taker: ContractAddress,
    price: u256,
    tokenId: u256,
    minPercentageToAsk: u128,
    params: Span<felt252>,
}
