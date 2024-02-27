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
    use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

    use openzeppelin::access::ownable::OwnableComponent;

    use flex::{DebugContractAddress, DisplayContractAddress};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        whitelisted_currency_count: usize,
        whitelisted_currencies: LegacyMap::<usize, ContractAddress>,
        whitelisted_currency_index: LegacyMap::<ContractAddress, usize>,
        initialized: bool,
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

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        proxy_admin: ContractAddress
    ) {
        self.initializer(owner, proxy_admin);
    }

    #[external(v0)]
    impl CurrencyManagerImpl of super::ICurrencyManager<ContractState> {
        fn initializer(
            ref self: ContractState, owner: ContractAddress, proxy_admin: ContractAddress
        ) {
            assert!(!self.initialized.read(), "CurrencyManager: already initialized");
            self.initialized.write(true);
            self.ownable.initializer(owner);
        }

        fn add_currency(ref self: ContractState, currency: ContractAddress) {
            self.ownable.assert_only_owner();
            let index = self.whitelisted_currency_index.read(currency);
            assert!(index.is_zero(), "CurrencyManager: currency {} already whitelisted", currency);
            let new_count = self.whitelisted_currency_count.read() + 1;
            self.whitelisted_currency_index.write(currency, new_count);
            self.whitelisted_currencies.write(new_count, currency);
            self.whitelisted_currency_count.write(new_count);
            let timestamp = get_block_timestamp();
            self.emit(CurrencyWhitelisted { currency, timestamp });
        }

        fn remove_currency(ref self: ContractState, currency: ContractAddress) {
            self.ownable.assert_only_owner();
            let index = self.whitelisted_currency_index.read(currency);
            assert!(!index.is_zero(), "CurrencyManager: currency {} not whitelisted", currency);
            let count = self.whitelisted_currency_count.read();

            let currency_at_last_index = self.whitelisted_currencies.read(count);
            self.whitelisted_currencies.write(index, currency_at_last_index);
            self.whitelisted_currencies.write(count, contract_address_const::<0>());
            self.whitelisted_currency_index.write(currency, 0);
            if (count != 1) {
                self.whitelisted_currency_index.write(currency_at_last_index, index);
            }
            self.whitelisted_currency_count.write(count - 1);
            let timestamp = get_block_timestamp();
            self.emit(CurrencyRemoved { currency, timestamp });
        }

        fn is_currency_whitelisted(self: @ContractState, currency: ContractAddress) -> bool {
            let index = self.whitelisted_currency_index.read(currency);
            if (index == 0) {
                return false;
            }
            true
        }

        fn whitelisted_currency_count(self: @ContractState) -> usize {
            self.whitelisted_currency_count.read()
        }

        fn whitelisted_currency(self: @ContractState, index: usize) -> ContractAddress {
            self.whitelisted_currencies.read(index)
        }
    }
}
