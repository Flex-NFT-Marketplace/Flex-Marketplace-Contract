use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC7743<TContractState> {
    fn mint(ref self: TContractState, to: ContractAddress, token_id: felt252);
    fn provide(
        self: @TContractState, 
        asset_name: ByteArray, 
        size: u256, file_hash: ByteArray, 
        ContractAddress provider, 
        transfer_value: felt252) -> felt252;
    fn transfer_from(ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: felt252);
    fn safe_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: felt252,
        data: Span<felt252>
    );
    fn is_owner(self: @TContractState, token_id: felt252, account: ContractAddress) -> bool;
    fn get_owners_count(self: @TContractState, token_id: felt252) -> u256;
    fn balance_of(self: @TContractState, owner: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: felt252) -> ContractAddress;
    fn set_transfer_value(token_id: felt252, new_transfer_value: u256);
    fn burn(token_id: felt252);
}