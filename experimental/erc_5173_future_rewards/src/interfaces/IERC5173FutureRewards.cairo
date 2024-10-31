use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC5173FutureRewards<TContractState> {
    /// @dev view functions
    fn get_fr_info(self: @TContractState, token_id: u256) -> (u8, u256, u256, u256, u256, Array<ContractAddress>);
    fn get_allotted_rewards(self: @TContractState, account: ContractAddress) -> u256;
    fn get_list_info(self: @TContractState, token_id: u256) -> (u256, ContractAddress, bool);

    /// @dev external functions
    fn list(ref self: TContractState, token_id: u256, sale_price: u256);
    fn unlist(ref self: TContractState, token_id: u256);
    fn buy(ref self: TContractState, token_id: u256) -> u256;
    fn release_rewards(ref self: TContractState, account: ContractAddress);
}
