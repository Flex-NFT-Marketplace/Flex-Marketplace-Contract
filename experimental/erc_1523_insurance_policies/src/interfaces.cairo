use starknet::ContractAddress;

use erc_1523_insurance_policies::types::{InsurancePolicy, PolicyStatus};

#[starknet::interface]
pub trait IERC1523<TContractState> {
    fn create_policy(ref self: TContractState, policy: InsurancePolicy) -> u256;
    fn update_policy(ref self: TContractState, token_id: u256, state: PolicyStatus);
    fn transfer_policy(ref self: TContractState, token_id: u256, to: ContractAddress);

    fn get_policy(self: @TContractState, token_id: u256) -> InsurancePolicy;
    fn get_policies_by_owner(
        self: @TContractState, owner: ContractAddress
    ) -> Array<InsurancePolicy>;
    fn get_user_policy_amount(self: @TContractState, user: ContractAddress) -> u64;

    fn activate_policy(ref self: TContractState, token_id: u256);
    fn expire_policy(ref self: TContractState, token_id: u256);
    fn cancel_policy(ref self: TContractState, token_id: u256);
    fn claim_policy(ref self: TContractState, token_id: u256);
}
