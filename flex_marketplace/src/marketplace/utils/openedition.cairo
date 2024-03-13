use starknet::ContractAddress;
use array::Array;

#[derive(Drop, Copy, Serde, starknet::Store)]
struct PublicDrop {
    mint_price: u256,
    start_time: u64,
    end_time: u64,
    max_mint_per_wallet: u64,
    restrict_fee_recipients: bool,
}

#[derive(Drop, Serde)]
struct MultiConfigureStruct {
    max_supply: u64,
    base_uri: felt252,
    contract_uri: felt252,
    flex_drop: ContractAddress,
    public_drop: PublicDrop,
    creator_payout_address: ContractAddress,
    allowed_fee_recipients: Array::<ContractAddress>,
    disallowed_fee_recipients: Array::<ContractAddress>,
    allowed_payers: Array::<ContractAddress>,
    disallowed_payers: Array::<ContractAddress>,
}
