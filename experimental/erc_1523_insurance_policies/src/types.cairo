use starknet::ContractAddress;

#[derive(Drop, starknet::Store, Serde, Clone, PartialEq)]
pub struct Policy {
    pub policyholder: ContractAddress,
    pub premium: u256,
    pub coveragePeriodStart: u256,
    pub coveragePeriodEnd: u256,
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

#[derive(Drop, Copy, starknet::Store, Serde, PartialEq)]
pub enum Property {
    Carrier,
    Risk,
    Status,
}
