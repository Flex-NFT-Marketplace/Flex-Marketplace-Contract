use starknet::ContractAddress;

#[derive(Drop, starknet::Store, Serde, Clone, PartialEq)]
pub struct UserRecord {
    pub token_id: u256,
    pub owner: ContractAddress,
    pub amount: u64,
    pub user: ContractAddress,
    pub expiry: u64
}
