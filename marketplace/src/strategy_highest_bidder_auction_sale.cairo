use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use marketplace::utils::order_types::{TakerOrder, MakerOrder};

#[starknet::interface]
trait IStrategyHighestBidderAuctionSale<TState> {
    fn initializer(ref self: TState, fee: u128, owner: ContractAddress);
    fn update_protocol_fee(ref self: TState, fee: u128);
    fn protocol_fee(self: @TState) -> u128;
    fn can_execute_taker_ask(
        self: @TState, taker_ask: TakerOrder, maker_bid: MakerOrder, extra_params: Span<felt252>
    ) -> (bool, u256, u128);
    fn can_execute_taker_bid(
        self: @TState, taker_bid: TakerOrder, maker_ask: MakerOrder
    ) -> (bool, u256, u128);
    fn upgrade(ref self: TState, impl_hash: ClassHash);
}

#[starknet::contract]
mod StrategyHighestBidderAuctionSale {
    use starknet::{ContractAddress, contract_address_const};
    use starknet::class_hash::ClassHash;
    use starknet::get_block_timestamp;
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent::InternalTrait;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    use marketplace::utils::order_types::{TakerOrder, MakerOrder};

    #[storage]
    struct Storage {
        protocol_fee: u128,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradable: UpgradeableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[abi(embed_v0)]
    impl StrategyHighestBidderAuctionSaleImpl of super::IStrategyHighestBidderAuctionSale<
        ContractState
    > {
        fn initializer(ref self: ContractState, fee: u128, owner: ContractAddress) {
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
            self: @ContractState,
            taker_ask: TakerOrder,
            maker_bid: MakerOrder,
            extra_params: Span<felt252>
        ) -> (bool, u256, u128) {
            let token_id_match: bool = maker_bid.token_id == taker_ask.token_id;
            let start_time_valid: bool = maker_bid.start_time < get_block_timestamp();
            let end_time_valid: bool = maker_bid.end_time > get_block_timestamp();
            let highest_bid_valid: bool = maker_bid
                .price >= taker_ask
                .price; // Check if the bid is equal or higher than the current highest bid.

            if (token_id_match && start_time_valid && end_time_valid && highest_bid_valid) {
                return (
                    true, maker_bid.token_id, maker_bid.price
                ); // Use maker_bid.price as the winning bid price.
            } else {
                return (false, maker_bid.token_id, maker_bid.price);
            }
        }

        fn can_execute_taker_bid(
            self: @ContractState, taker_bid: TakerOrder, maker_ask: MakerOrder
        ) -> (bool, u256, u128) {
            let token_id_match: bool = maker_ask.token_id == taker_bid.token_id;
            let start_time_valid: bool = maker_ask.start_time < get_block_timestamp();
            let end_time_valid: bool = maker_ask.end_time > get_block_timestamp();
            let highest_bid_valid: bool = taker_bid
                .price >= maker_ask
                .price; // Check if the bid is equal or higher than the current highest bid.

            if (token_id_match && start_time_valid && end_time_valid && highest_bid_valid) {
                return (
                    true, maker_ask.token_id, taker_bid.price
                ); // Use taker_bid.price as the winning bid price.
            } else {
                return (false, maker_ask.token_id, taker_bid.price);
            }
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradable._upgrade(impl_hash);
        }
    }
}

