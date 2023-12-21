use starknet::ContractAddress;

#[starknet::interface]
trait IExecutionManager<TState> {
    fn initializer(ref self: TState, owner: ContractAddress, proxy_admin: ContractAddress);
    fn add_strategy(ref self: TState, strategy: felt252);
    fn remove_strategy(ref self: TState, strategy: felt252);
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn owner(self: @TState) -> ContractAddress;
    fn is_strategy_whitelisted(self: @TState, strategy: felt252) -> bool;
    fn get_whitelisted_strategies_count(self: @TState) -> usize;
    fn get_whitelisted_strategy(self: @TState, index: usize) -> felt252;
}

#[starknet::contract]
mod ExecutionManager {
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::{ContractAddress, contract_address_const};
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        whitelisted_strategies_count: usize,
        whitelisted_strategies: LegacyMap::<usize, felt252>,
        whitelisted_strategies_index: LegacyMap::<felt252, usize>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StrategyRemoved: StrategyRemoved,
        StrategyWhitelisted: StrategyWhitelisted,
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct StrategyRemoved {
        strategy: felt252,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct StrategyWhitelisted {
        strategy: felt252,
        timestamp: u64
    }

    #[external(v0)]
    impl ExecutionManagerImpl of super::IExecutionManager<ContractState> {
        fn initializer(
            ref self: ContractState, owner: ContractAddress, proxy_admin: ContractAddress
        ) { // TODO
        }

        fn add_strategy(ref self: ContractState, strategy: felt252) { // TODO
        }

        fn remove_strategy(ref self: ContractState, strategy: felt252) { // TODO
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) { // TODO
        }

        fn owner(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn is_strategy_whitelisted(self: @ContractState, strategy: felt252) -> bool {
            // TODO
            true
        }

        fn get_whitelisted_strategies_count(self: @ContractState) -> usize {
            // TODO
            0
        }

        fn get_whitelisted_strategy(self: @ContractState, index: usize) -> felt252 {
            // TODO
            0
        }
    }
}
