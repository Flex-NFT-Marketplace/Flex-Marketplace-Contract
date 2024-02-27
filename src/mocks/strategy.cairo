use flex::marketplace::utils::order_types::{MakerOrder, TakerOrder};
use starknet::ContractAddress;

#[starknet::interface]
trait IExecutionStrategy<TState> {
    fn protocolFee(self: @TState) -> u128;
    fn canExecuteTakerAsk(
        self: @TState, taker_ask: TakerOrder, maker_bid: MakerOrder, extra_params: Array<felt252>
    ) -> (bool, u256, u128);
    fn canExecuteTakerBid(
        self: @TState, taker_bid: TakerOrder, maker_ask: MakerOrder
    ) -> (bool, u256, u128);
}

#[starknet::interface]
trait IAuctionStrategy<TState> {
    fn auctionRelayer(self: @TState) -> ContractAddress;
    fn canExecuteAuctionSale(
        self: @TState, maker_ask: MakerOrder, maker_bid: MakerOrder
    ) -> (bool, u256, u128);
}

#[starknet::contract]
mod Strategy {
    use flex::marketplace::utils::order_types::{MakerOrder, TakerOrder};
    use starknet::ContractAddress;

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl MockExecutionStrategyImpl of super::IExecutionStrategy<ContractState> {
        fn protocolFee(self: @ContractState) -> u128 {
            1000
        }
        fn canExecuteTakerAsk(
            self: @ContractState,
            taker_ask: super::TakerOrder,
            maker_bid: super::MakerOrder,
            extra_params: Array<felt252>
        ) -> (bool, u256, u128) {
            (true, 1, 1)
        }
        fn canExecuteTakerBid(
            self: @ContractState, taker_bid: super::TakerOrder, maker_ask: super::MakerOrder
        ) -> (bool, u256, u128) {
            (true, 1, 1)
        }
    }

    #[external(v0)]
    impl MockAuctionStrategyImpl of super::IAuctionStrategy<ContractState> {
        fn auctionRelayer(self: @ContractState) -> ContractAddress {
            starknet::contract_address_const::<'RELAYER'>()
        }
        fn canExecuteAuctionSale(
            self: @ContractState, maker_ask: MakerOrder, maker_bid: MakerOrder
        ) -> (bool, u256, u128) {
            (true, 1, 1)
        }
    }
}

