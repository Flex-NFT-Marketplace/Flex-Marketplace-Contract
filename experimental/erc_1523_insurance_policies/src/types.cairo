use starknet::ContractAddress;

#[derive(Drop, starknet::Store, Serde, Clone, PartialEq)]
pub struct Policy {
    pub policy_holder: ContractAddress,
    pub premium: u256,
    pub coverage_period_start: u256,
    pub coverage_period_end: u256,
    pub risk: ByteArray,
    pub underwriter: ContractAddress,
    pub metadataURI: ByteArray,
    pub state: State,
}

#[derive(Drop, Copy, starknet::Store, Serde, PartialEq)]
pub enum State {
    Active,
    Expired,
    Claimed,
}
