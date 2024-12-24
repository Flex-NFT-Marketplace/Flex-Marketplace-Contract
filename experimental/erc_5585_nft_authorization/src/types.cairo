use starknet::ContractAddress;
// use core::array::ArrayTrait;

#[derive(Drop, Serde, starknet::Store, Clone, PartialEq)]
pub struct UserRecord {
    pub user: ContractAddress,
    pub expires: u64
}

#[derive(Drop, Serde, starknet::Store, Clone, PartialEq)]
pub struct NFTDetails {
    pub owner: ContractAddress,
    pub approved: ContractAddress,
    pub token_uri: felt252
}
