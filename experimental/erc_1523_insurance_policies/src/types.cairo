use starknet::ContractAddress;

#[derive(Drop, starknet::Store, Serde, Clone, PartialEq)]
pub struct InsurancePolicy {
    policy_id: felt252,
    owner: ContractAddress,
    carrier: ContractAddress,
    risk_type: felt252,
    premium: u256,
    coverage_amount: u256,
    start_date: u64,
    end_date: u64,
    status: PolicyStatus,
    additional_details: felt252,
}

#[derive(Drop, Copy, starknet::Store, Serde, PartialEq)]
pub enum PolicyStatus {
    Active,
    Expired,
    Claimed,
}