use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Hash, PartialEq, starknet::Store)]
struct Item {
    collection: ContractAddress,
    tokenId: u256
}

#[derive(Copy, Drop, Serde, Hash, starknet::Store)]
struct Stake {
    owner: ContractAddress,
    stakedAt: u64
}

#[starknet::interface]
trait IFlexStakingPool<TContractState> {
    fn setAllowedCollection(ref self: TContractState, collection: ContractAddress, allowed: bool);
    fn setRewardPerUnitTime(ref self: TContractState, collection: ContractAddress, reward: u256);
    fn setTimeUnit(ref self: TContractState, collection: ContractAddress, timeUnit: u64);
    fn stakeNFT(ref self: TContractState, collection: ContractAddress, tokenId: u256);
    fn unstakeNFT(ref self: TContractState, collection: ContractAddress, tokenId: u256);
    fn getUserPointByItem(
        self: @TContractState, user: ContractAddress, nftCollection: ContractAddress, tokenId: u256
    ) -> u256;
    fn getUserTotalPoint(self: @TContractState, user: ContractAddress,) -> u256;
}

#[starknet::interface]
trait IAdditionalImpl<TContractState> {
    fn getStakedStatus(self: @TContractState, collection: ContractAddress, tokenId: u256) -> Stake;
    fn getItemStaked(self: @TContractState, user: ContractAddress) -> Array::<Item>;
    fn isEligibleCollection(self: @TContractState, collection: ContractAddress) -> bool;
    fn totalStaked(self: @TContractState, collection: ContractAddress) -> u256;
    fn getTimeUnit(self: @TContractState, collection: ContractAddress) -> u64;
    fn getRewardPerUnitTime(self: @TContractState, collection: ContractAddress) -> u256;
}
