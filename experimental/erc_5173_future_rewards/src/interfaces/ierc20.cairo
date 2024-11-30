use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC20<TContractState> {
    fn total_supply(self: @TContractState) -> felt252;
    fn balance_of(self: @TContractState, account: ContractAddress) -> felt252;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> felt252;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: felt252) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: felt252
    ) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: felt252) -> bool;
}