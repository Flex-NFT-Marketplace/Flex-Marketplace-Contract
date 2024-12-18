use starknet::ContractAddress;

#[derive(Drop, starknet::Store, Serde, Clone, PartialEq)]
pub struct Listing {
    pub sale_price: u256,
    pub expires: u64,
    pub supported_token: ContractAddress,
    pub historical_price: u256
}
