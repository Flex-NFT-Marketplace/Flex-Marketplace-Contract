use starknet::ContractAddress;
use erc5006_cairo::types::UserRecord;

#[starknet::interface]
pub trait IERC5006<TState> {
    fn usable_balance_of(self: @TState, account: ContractAddress, token_id: u256) -> u256;

    fn frozen_balance_of(self: @TState, account: ContractAddress, token_id: u256) -> u256;

    fn user_record_of(self: @TState, record_id: u256) -> UserRecord;

    fn create_user_record(
        ref self: TState,
        owner: ContractAddress,
        user: ContractAddress,
        token_id: u256,
        amount: u64,
        expiry: u64
    ) -> u256;

    fn delete_user_record(ref self: TState, record_id: u256);
}
