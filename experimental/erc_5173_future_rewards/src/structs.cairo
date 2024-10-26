use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct FRInfo {
    pub profit_percentage: u256,
    pub successive_ratio: u256,
    pub owner_amount: u256,
    pub last_sold_price: u256,
    pub num_generations: u256,
    pub is_valid: bool
}

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct ListInfo {
    pub sale_price: u256,
    pub lister: ContractAddress,
    pub is_listed: bool
}

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct AllottedRewards {
    pub allotted_rewards: u256,
    pub is_valid: bool
}

#[derive(Drop, starknet::Event)]
pub struct RewardsDistributed {
    #[key]
    pub token_id: u256,
    #[key]
    pub sold_price: u256,
    #[key]
    pub allocated_rewards: u256
}

#[derive(Drop, starknet::Event)]
pub struct RewardsClaimed {
    #[key]
    pub account: ContractAddress,
    #[key]
    pub amount: u256
}

#[derive(Drop, starknet::Event)]
pub struct Listed {
    #[key]
    pub token_id: u256,
    #[key]
    pub sale_price: u256
}

#[derive(Drop, starknet::Event)]
pub struct Unlisted {
    #[key]
    pub token_id: u256
}

#[derive(Drop, starknet::Event)]
pub struct Bought {
    #[key]
    pub token_id: u256,
    #[key]
    pub sale_price: u256
}

