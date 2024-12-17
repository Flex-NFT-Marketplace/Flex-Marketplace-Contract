use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC7743<TContractState> {
    fn mint(ref self: TContractState, to: ContractAddress, token_id: felt252);
    fn provide(ByteArray asset_name, u256 size, ByteArray file_hash, ContractAddress provider, u256 transfer_value) -> felt252;
    fn transfer_from(ContractAddress from, ContractAddress to, u256 token_id);
    fn is_owner(u256 token_id, ContractAddress account) -> bool;
    fn get_owners_count(u256 token_id) -> u256;
    fn balance_of(ContractAddress owner) -> u256;
    fn owner_of(u256 token_d) -> ContractAddress;
    fn set_transfer_value(u256 token_id, u256 new_transfer_value);
    fn burn(u256 token_id);
}