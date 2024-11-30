use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC5173<TContractState> {
    fn mint(ref self: TContractState, to: ContractAddress, token_id: felt252);
    fn transfer(ref self: TContractState, to: ContractAddress, token_id: felt252 );
    fn distribute_rewards(ref self: TContractState, reward_amount: felt252, token_id: felt252);
    fn get_token_owner(self: @TContractState, token_id: felt252) -> ContractAddress;
    fn get_reward_balance(self: @TContractState, address: ContractAddress) -> felt252;
}