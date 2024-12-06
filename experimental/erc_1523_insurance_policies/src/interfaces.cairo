use starknet::ContractAddress;

use erc_1523_insurance_policies::types::{Policy, State};

#[starknet::interface]
pub trait IERC1523PolicyMetadata<TState> {
    fn policyMetadata(self: @TState, tokenId: u256, propertyPathHash: ByteArray) -> ByteArray;
}


#[starknet::interface]
pub trait IERC1523<TState> {
    fn create_policy(ref self: TState, policy: Policy) -> token_id;
    fn update_policy_state(ref self: TState, state: State);

    fn get_policy(self: @TState, token_id: u256) -> Policy;
    fn get_all_user_policies(self: @TState, user: ContractAddress) -> Span<Policy>;
}
