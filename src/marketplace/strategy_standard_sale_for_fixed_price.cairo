use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use flex::marketplace::utils::order_types::{TakerOrder, MakerOrder};

#[starknet::interface]
trait IStrategyStandardSaleForFixedPrice<TState> {
    fn initializer(ref self: TState, fee: u128, owner: ContractAddress);
    fn update_protocol_fee(ref self: TState, fee: u128);
    fn protocol_fee(self: @TState) -> u128;
    fn can_execute_taker_ask(
        self: @TState, taker_ask: TakerOrder, maker_bid: MakerOrder
    ) -> (bool, u256, u128);
    fn can_execute_taker_bid(
        self: @TState, taker_bid: TakerOrder, maker_ask: MakerOrder
    ) -> (bool, u256, u128);
}

#[starknet::contract]
mod StrategyStandardSaleForFixedPrice {
    use starknet::{ContractAddress, contract_address_const};
    use starknet::class_hash::ClassHash;
    use starknet::get_block_timestamp;
    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    use flex::marketplace::utils::order_types::{TakerOrder, MakerOrder};

    #[storage]
    struct Storage {
        initialized: bool,
        protocol_fee: u128,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, fee: u128, owner: ContractAddress) {
        self.initializer(fee, owner);
    }

    #[external(v0)]
    impl StrategyStandardSaleForFixedPriceImpl of super::IStrategyStandardSaleForFixedPrice<
        ContractState
    > {
        fn initializer(ref self: ContractState, fee: u128, owner: ContractAddress) {
            assert!(
                !self.initialized.read(), "StrategyStandardSaleForFixedPrice: already initialized"
            );
            self.initialized.write(true);
            self.ownable.initializer(owner);
            self.protocol_fee.write(fee);
        }

        fn update_protocol_fee(ref self: ContractState, fee: u128) {
            self.ownable.assert_only_owner();
            self.protocol_fee.write(fee);
        }

        fn protocol_fee(self: @ContractState) -> u128 {
            self.protocol_fee.read()
        }

        fn can_execute_taker_ask(
            self: @ContractState, taker_ask: TakerOrder, maker_bid: MakerOrder,
        ) -> (bool, u256, u128) {
            let price_match: bool = (maker_bid.price * taker_ask.amount)
                / maker_bid.amount >= taker_ask.price;
            let token_id_match: bool = maker_bid.token_id == taker_ask.token_id;
            let start_time_valid: bool = maker_bid.start_time < get_block_timestamp();
            let end_time_valid: bool = maker_bid.end_time > get_block_timestamp();
            if (price_match && token_id_match && start_time_valid && end_time_valid) {
                return (true, maker_bid.token_id, taker_ask.amount);
            } else {
                return (false, maker_bid.token_id, taker_ask.amount);
            }
        }

        fn can_execute_taker_bid(
            self: @ContractState, taker_bid: TakerOrder, maker_ask: MakerOrder
        ) -> (bool, u256, u128) {
            let price_match: bool = (maker_ask.price * taker_bid.amount)
                / maker_ask.amount <= taker_bid.price;
            let token_id_match: bool = maker_ask.token_id == taker_bid.token_id;
            let start_time_valid: bool = maker_ask.start_time < get_block_timestamp();
            let end_time_valid: bool = maker_ask.end_time > get_block_timestamp();
            if (price_match && token_id_match && start_time_valid && end_time_valid) {
                return (true, maker_ask.token_id, taker_bid.amount);
            } else {
                return (false, maker_ask.token_id, taker_bid.amount);
            }
        }
    }
}
