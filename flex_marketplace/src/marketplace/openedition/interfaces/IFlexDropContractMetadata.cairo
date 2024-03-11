#[starknet::interface]
trait IFlexDropContractMetadata<TContractState> {
    fn set_base_uri(ref self: TContractState, new_token_uri: felt252);
    fn set_contract_uri(ref self: TContractState, new_contract_uri: felt252);
    fn set_max_supply(ref self: TContractState, new_max_supply: u64);
    fn get_base_uri(self: @TContractState) -> felt252;
    fn get_contract_uri(self: @TContractState) -> felt252;
    fn get_max_supply(self: @TContractState) -> u64;
}
