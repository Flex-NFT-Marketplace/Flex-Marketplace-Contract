use starknet::ContractAddress;
use array::Array;

#[derive(Drop, Copy, Serde, starknet::Store)]
struct PhaseDrop {
    mint_price: u256,
    currency: ContractAddress,
    start_time: u64,
    end_time: u64,
    max_mint_per_wallet: u64,
    phase_type: u8 // 1 for public sale, 2 for private sale...
}

#[derive(Drop, Serde)]
struct MultiConfigureStruct {
    max_supply: u64,
    base_uri: felt252,
    contract_uri: felt252,
    flex_drop: ContractAddress,
    phase_drop: PhaseDrop,
    new_phase: bool,
    creator_payout_address: ContractAddress,
    fee_recipient: ContractAddress,
    allowed_payers: Array::<ContractAddress>,
    disallowed_payers: Array::<ContractAddress>,
}
