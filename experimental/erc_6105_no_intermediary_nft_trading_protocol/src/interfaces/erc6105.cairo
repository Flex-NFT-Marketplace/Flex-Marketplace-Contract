use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC6105<TState> {
    fn list_item(ref self: TState, token_id: u256, sale_price: u256, expires: u64, supported_token: ContractAddress);
    fn list_item_with_benchmark(ref self: TState, token_id: u256, sale_price: u256, expires: u64, supported_token: ContractAddress, benchmark_price: u256);
    fn delist_item(ref self: TState, token_id: u256);
    fn buy_item(ref self: TState, token_id: u256, sale_price: u256, supported_token: ContractAddress);
    fn get_listing(self: @TState, token_id: u256) -> (u256, u64, ContractAddress, u256);
}