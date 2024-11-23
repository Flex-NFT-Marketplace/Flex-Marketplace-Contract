use starknet::ContractAddress;

#[starknet::interface]
pub trait IFractionalNFT<TContractState> {
    fn initialized(ref self: TContractState, nft_collection: ContractAddress, accepted_purchase_token: ContractAddress, token_id: u256, amount: u256);
    fn put_for_sell(ref self: TContractState, price: u256);
    fn purchase(ref self: TContractState, amount: u256);
    fn redeem(ref self: TContractState, amount: u256);

    fn nft_collection(self: @TContractState) -> ContractAddress;
    fn token_id(self: @TContractState) -> u256;
    fn is_initialized(self: @TContractState) -> bool;
    fn for_sale(self: @TContractState) -> bool;
    fn redeemable(self: @TContractState) -> bool;
    fn sale_price(self: @TContractState) -> u256;
}