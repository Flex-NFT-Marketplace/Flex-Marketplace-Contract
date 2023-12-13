use starknet::ContractAddress;

#[starknet::interface]
trait ICurrencyManager<TState> {
    fn initializer(ref self: TState, owner: ContractAddress, proxy_admin: ContractAddress);
    fn add_currency(ref self: TState, currency: ContractAddress);
    fn remove_currency(ref self: TState, currency: ContractAddress);
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn owner(self: @TState) -> ContractAddress;
    fn is_currency_whitelisted(self: @TState, currency: ContractAddress) -> bool;
    fn whitelisted_currency_count(self: @TState) -> usize;
    fn whitelisted_currency(self: @TState, index: usize) -> ContractAddress;
}

#[starknet::contract]
mod CurrencyManager {
    use starknet::{ContractAddress, contract_address_const};

    #[storage]
    struct Storage {
        whitelisted_currency_count: usize,
        whitelisted_currencies: LegacyMap::<usize, ContractAddress>,
        whitelisted_currency_index: LegacyMap::<ContractAddress, usize>,
    }

    #[external(v0)]
    impl CurrencyManager of super::ICurrencyManager<ContractState> {
        fn initializer(
            ref self: ContractState, owner: ContractAddress, proxy_admin: ContractAddress
        ) { // TODO
        }

        fn add_currency(ref self: ContractState, currency: ContractAddress) { // TODO
        }

        fn remove_currency(ref self: ContractState, currency: ContractAddress) { // TODO
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) { // TODO
        }

        fn owner(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn is_currency_whitelisted(self: @ContractState, currency: ContractAddress) -> bool {
            // TODO
            true
        }

        fn whitelisted_currency_count(self: @ContractState) -> usize {
            // TODO
            0
        }

        fn whitelisted_currency(self: @ContractState, index: usize) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }
    }
}
