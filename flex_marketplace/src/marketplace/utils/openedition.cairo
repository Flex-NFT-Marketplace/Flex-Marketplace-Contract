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

#[derive(Drop, Copy, Serde)]
struct WhiteListParam {
    phase_id: u64,
    nft_address: ContractAddress,
    minter: ContractAddress,
}

#[derive(Drop, Serde)]
struct MultiConfigureStruct {
    base_uri: ByteArray,
    contract_uri: ByteArray,
    flex_drop: ContractAddress,
    phase_drop: PhaseDrop,
    new_phase: bool,
    creator_payout_address: ContractAddress,
    fee_recipient: ContractAddress,
    allowed_payers: Array::<ContractAddress>,
    disallowed_payers: Array::<ContractAddress>,
}
