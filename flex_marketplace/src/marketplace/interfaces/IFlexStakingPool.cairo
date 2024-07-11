use starknet::ContractAddress;

#[starknet::interface]
trait IFlexStakingPool<TContractState> {
    fn stakeNFT(ref self: TContractState, collection: ContractAddress, tokenId: u256);
    fn unstakeNFT(ref self: TContractState, collection: ContractAddress, tokenId: u256);
    fn getUserPoint(
        self: @TContractState, user: ContractAddress, nftCollection: ContractAddress, tokenId: u256
    ) -> u256;
}
