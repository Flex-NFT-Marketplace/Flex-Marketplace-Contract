use starknet::ContractAddress;

#[starknet::interface]
trait IExecutionManager<TState> {
    fn initializer(ref self: TState, owner: ContractAddress);
    fn add_strategy(ref self: TState, strategy: ContractAddress);
    fn remove_strategy(ref self: TState, strategy: ContractAddress);
    fn is_strategy_whitelisted(self: @TState, strategy: ContractAddress) -> bool;
    fn get_whitelisted_strategies_count(self: @TState) -> usize;
    fn get_whitelisted_strategy(self: @TState, index: usize) -> ContractAddress;
}

#[starknet::contract]
mod ExecutionManager {
    use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

    use flex::{DebugContractAddress, DisplayContractAddress};

    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        initialized: bool,
        whitelisted_strategies_count: usize,
        whitelisted_strategies: LegacyMap::<usize, ContractAddress>,
        whitelisted_strategies_index: LegacyMap::<ContractAddress, usize>,
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
        strategy: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct StrategyWhitelisted {
        strategy: ContractAddress,
        timestamp: u64
    }

    #[external(v0)]
    impl ExecutionManagerImpl of super::IExecutionManager<ContractState> {
        fn initializer(ref self: ContractState, owner: ContractAddress) {
            assert!(!self.initialized.read(), "ExecutionManager: already initialized");
            self.initialized.write(true);
            self.ownable.initializer(owner)
        }

        fn add_strategy(ref self: ContractState, strategy: ContractAddress) {
            self.ownable.assert_only_owner();
            assert!(
                self.whitelisted_strategies_index.read(strategy).is_zero(),
                "ExecutionManager: strategy {} already whitelisted",
                strategy
            );
            let new_index = self.whitelisted_strategies_count.read() + 1;
            self.whitelisted_strategies.write(new_index, strategy);
            self.whitelisted_strategies_index.write(strategy, new_index);
            self.whitelisted_strategies_count.write(new_index);

            self.emit(StrategyWhitelisted { strategy, timestamp: get_block_timestamp() });
        }

        fn remove_strategy(ref self: ContractState, strategy: ContractAddress) {
            self.ownable.assert_only_owner();
            let index = self.whitelisted_strategies_index.read(strategy);
            assert!(!index.is_zero(), "ExecutionManager: strategy {} not whitelisted", strategy);
            let count = self.whitelisted_strategies_count.read();

            let strategy_at_last_index = self.whitelisted_strategies.read(count);
            self.whitelisted_strategies.write(index, strategy_at_last_index);
            self.whitelisted_strategies.write(count, contract_address_const::<0>());
            self.whitelisted_strategies_index.write(strategy, 0);
            self.whitelisted_strategies_count.write(count - 1);

            self.emit(StrategyRemoved { strategy, timestamp: get_block_timestamp() });
        }

        fn is_strategy_whitelisted(self: @ContractState, strategy: ContractAddress) -> bool {
            !self.whitelisted_strategies_index.read(strategy).is_zero()
        }

        fn get_whitelisted_strategies_count(self: @ContractState) -> usize {
            self.whitelisted_strategies_count.read()
        }

        fn get_whitelisted_strategy(self: @ContractState, index: usize) -> ContractAddress {
            self.whitelisted_strategies.read(index)
        }
    }
}
