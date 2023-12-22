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

#[starknet::contract]
mod CurrencyManager {
    use starknet::{ContractAddress, contract_address_const};

    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        whitelisted_currency_count: usize,
        whitelisted_currencies: LegacyMap::<usize, ContractAddress>,
        whitelisted_currency_index: LegacyMap::<ContractAddress, usize>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CurrencyRemoved: CurrencyRemoved,
        CurrencyWhitelisted: CurrencyWhitelisted,
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CurrencyRemoved {
        currency: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct CurrencyWhitelisted {
        currency: ContractAddress,
        timestamp: u64,
    }

    #[external(v0)]
    impl CurrencyManagerImpl of super::ICurrencyManager<ContractState> {
        fn initializer(
            ref self: ContractState, owner: ContractAddress, proxy_admin: ContractAddress
        ) { // TODO
        }

        fn add_currency(ref self: ContractState, currency: ContractAddress) { // TODO
        }

        fn remove_currency(ref self: ContractState, currency: ContractAddress) { // TODO
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

