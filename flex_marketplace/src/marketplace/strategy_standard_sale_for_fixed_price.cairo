use starknet::ContractAddress;

use flex::marketplace::utils::order_types::{TakerOrder, MakerOrder};

#[starknet::interface]
trait IStrategyStandardSaleForFixedPrice<TState> {
    fn initializer(
        ref self: TState, fee: u128, owner: ContractAddress, proxy_admin: ContractAddress
    );
    fn update_protocol_fee(ref self: TState, fee: u128);
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn owner(self: @TState) -> ContractAddress;
    fn protocol_fee(self: @TState) -> u128;
    fn can_execute_taker_ask(
        self: @TState, taker_ask: TakerOrder, maker_bid: MakerOrder, extra_params: Span<felt252>
    ) -> (bool, u256, u128);
    fn can_execute_taker_bid(
        self: @TState, taker_bid: TakerOrder, maker_ask: MakerOrder
    ) -> (bool, u256, u128);
}

#[starknet::contract]
mod StrategyStandardSaleForFixedPrice {
    use starknet::{ContractAddress, contract_address_const};

    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    use flex::marketplace::utils::order_types::{TakerOrder, MakerOrder};

    #[storage]
    struct Storage {
        protocol_fee: u128,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnableEvent: OwnableComponent::Event,
    }

    #[external(v0)]
    impl StrategyStandardSaleForFixedPriceImpl of super::IStrategyStandardSaleForFixedPrice<
        ContractState
    > {
        fn initializer(
            ref self: ContractState, fee: u128, owner: ContractAddress, proxy_admin: ContractAddress
        ) { // TODO
        }

        fn update_protocol_fee(ref self: ContractState, fee: u128) { // TODO
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) { // TODO
        }

        fn owner(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn protocol_fee(self: @ContractState) -> u128 {
            // TODO
            0
        }

        fn can_execute_taker_ask(
            self: @ContractState,
            taker_ask: TakerOrder,
            maker_bid: MakerOrder,
            extra_params: Span<felt252>
        ) -> (bool, u256, u128) {
            // TODO
            (true, 0, 0)
        }
        fn can_execute_taker_bid(
            self: @ContractState, taker_bid: TakerOrder, maker_ask: MakerOrder
        ) -> (bool, u256, u128) {
            // TODO
            (true, 0, 0)
        }
    }
}
