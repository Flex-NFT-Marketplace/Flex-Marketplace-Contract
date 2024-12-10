use starknet::ContractAddress;

use erc_1523_insurance_policies::types::{InsurancePolicy, PolicyStatus};

#[starknet::interface]
pub trait IERC1523<TContractState> {
    fn create_policy(ref self: TContractState, policy: InsurancePolicy) -> u256;

    fn update_policy(
        ref self: TContractState, 
        token_id: u256,
        status: PolicyStatus
    );

    fn transfer_policy(
        ref self: TContractState, 
        policy_id: felt252, 
        to: ContractAddress
    );

    // Policy inquiry methods
    fn get_policy(self: @TContractState, policy_id: felt252) -> InsurancePolicy;
    fn get_policies_by_owner(self: @TContractState, owner: ContractAddress) -> Array<InsurancePolicy>;
    
    // Policy lifecycle methods
    fn activate_policy(ref self: TContractState, policy_id: felt252);
    fn expire_policy(ref self: TContractState, policy_id: felt252);
    fn cancel_policy(ref self: TContractState, policy_id: felt252);
    fn claim_policy(ref self: TContractState, policy_id: felt252);
}