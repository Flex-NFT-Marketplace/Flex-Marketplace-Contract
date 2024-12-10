use starknet::ContractAddress;

#[derive(Drop, starknet::Store, Serde, Clone, PartialEq)]
pub struct InsurancePolicy {
    // pub policy_id: felt252,
    pub policy_holder: ContractAddress,
    pub underwriter: ContractAddress,
    pub risk: ByteArray,
    pub premium: u256,
    // pub coverage_amount: u256,
    pub coverage_period_start: u256,
    pub coverage_period_end: u256,
    pub state: PolicyStatus,
    // pub additional_details: felt252,
    pub metadataURI: ByteArray
}

#[derive(Drop, Copy, starknet::Store, Serde, PartialEq)]
pub enum PolicyStatus {
    Active,
    Expired,
    Claimed,
    Cancelled,
}
