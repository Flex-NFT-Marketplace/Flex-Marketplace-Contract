use starknet::ContractAddress;

#[starknet::interface]
trait ICurrencyManager<TState> {
    fn initializer(ref self: TState, owner: ContractAddress, proxy_admin: ContractAddress);
    fn add_currency(ref self: TState, currency: ContractAddress);
    fn remove_currency(ref self: TState, currency: ContractAddress);
    fn is_currency_whitelisted(self: @TState, currency: ContractAddress) -> bool;
    fn whitelisted_currency_count(self: @TState) -> usize;
    fn whitelisted_currency(self: @TState, index: usize) -> ContractAddress;
}
