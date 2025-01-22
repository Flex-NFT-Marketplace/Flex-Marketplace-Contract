use starknet::{ContractAddress, ClassHash};

#[derive(Drop, Serde, Copy, starknet::Store)]
struct DropDetail {
    drop_type: u8,
    secure_amount: u256,
    is_random_to_subscribers: bool,
    from_top_supporter: u64,
    to_top_supporter: u64,
    start_time: u64,
    expire_time: u64,
}

#[derive(Drop, Copy, Serde, PartialEq)]
enum CollectibleRarity {
    Common,
    Rare,
    Legendary,
    Ultimate,
}

impl CollectibleRarityInto of Into<CollectibleRarity, felt252> {
    fn into(self: CollectibleRarity) -> felt252 {
        match self {
            CollectibleRarity::Common => 'common',
            CollectibleRarity::Rare => 'rare',
            CollectibleRarity::Legendary => 'legendary',
            CollectibleRarity::Ultimate => 'ultimate',
        }
    }
}

#[starknet::interface]
trait IFlexHausFactory<TContractState> {
    fn create_collectible(
        ref self: TContractState,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
        total_supply: u256,
        rarity: felt252,
    );
    fn create_drop(
        ref self: TContractState,
        collectible: ContractAddress,
        drop_type: u8,
        secure_amount: u256,
        is_random_to_subscribers: bool,
        from_top_supporter: u64,
        to_top_supporter: u64,
        start_time: u64,
        expire_time: u64,
    );
    fn update_collectible_drop_phase(
        ref self: TContractState,
        collectible: ContractAddress,
        drop_type: u8,
        secure_amount: u256,
        is_random_to_subscribers: bool,
        from_top_supporter: u64,
        to_top_supporter: u64,
        start_time: u64,
        expire_time: u64,
    );
    fn update_collectible_detail(
        ref self: TContractState,
        collectible: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
        total_supply: u256,
        rarity: felt252,
    );
    fn claim_collectible(
        ref self: TContractState, collectible: ContractAddress, keys: Array<felt252>
    );
    fn set_protocol_fee(ref self: TContractState, new_fee: u256);
    fn set_protocol_currency(ref self: TContractState, new_currency: ContractAddress);
    fn set_fee_recipient(ref self: TContractState, new_recipient: ContractAddress);
    fn set_signer(ref self: TContractState, new_signer: ContractAddress);
    fn set_flex_haus_collectible_class(ref self: TContractState, new_class_hash: ClassHash);
    fn set_min_duration_time_for_update(ref self: TContractState, new_duration: u64);
    fn get_collectible_drop(self: @TContractState, collectible: ContractAddress) -> DropDetail;
    fn get_protocol_fee(self: @TContractState) -> u256;
    fn get_protocol_currency(self: @TContractState) -> ContractAddress;
    fn get_fee_recipient(self: @TContractState) -> ContractAddress;
    fn get_signer(self: @TContractState) -> ContractAddress;
    fn get_flex_haus_collectible_class(self: @TContractState) -> ClassHash;
    fn get_min_duration_time_for_update(self: @TContractState) -> u64;
    fn get_all_collectibles_addresses(self: @TContractState) -> Array<ContractAddress>;
    fn get_total_collectibles_count(self: @TContractState) -> u64;
    fn get_collectibles_of_owner(
        self: @TContractState, owner: ContractAddress
    ) -> Array<ContractAddress>;
}
