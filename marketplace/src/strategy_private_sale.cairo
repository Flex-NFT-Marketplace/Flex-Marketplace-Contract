use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use marketplace::utils::order_types::{TakerOrder, MakerOrder};

#[starknet::interface]
trait IStrategyPrivateSale<TState> {
    fn initializer(ref self: TState, fee: u128, owner: ContractAddress);
    fn update_protocol_fee(ref self: TState, fee: u128);
    fn protocol_fee(self: @TState) -> u128;
    fn add_address_to_whitelist(ref self: TState, order_nonce: u128, address: ContractAddress);
    fn remove_address_from_whitelist(ref self: TState, order_nonce: u128, address: ContractAddress);
    fn is_address_whitelisted(self: @TState, order_nonce: u128, address: ContractAddress) -> bool;
    fn order_whitelist_count(self: @TState, order_nonce: u128) -> u256;
    fn whitelisted_address(self: @TState, order_nonce: u128, index: u256) -> ContractAddress;
    fn can_execute_taker_ask(
        self: @TState, taker_ask: TakerOrder, maker_bid: MakerOrder, extra_params: Span<felt252>
    ) -> (bool, u256, u128);
    fn can_execute_taker_bid(
        self: @TState, taker_bid: TakerOrder, maker_ask: MakerOrder
    ) -> (bool, u256, u128);
    fn upgrade(ref self: TState, impl_hash: ClassHash);
}

#[starknet::contract]
mod StrategyPrivateSale {
    use core::array::ArrayTrait;
use marketplace::utils::order_types::{TakerOrder, MakerOrder};
    use starknet::{
        ContractAddress, contract_address_const, class_hash::ClassHash, get_block_timestamp,
        get_caller_address
    };
    use openzeppelin::{
        access::ownable::OwnableComponent,
        upgrades::{upgradeable::UpgradeableComponent::InternalTrait, UpgradeableComponent}
    };

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        protocol_fee: u128,
        order_whitelist: LegacyMap<(u128,u256), ContractAddress>, // <order_nonce, <u256, ContractAddress>>
        order_whitelist_index: LegacyMap<(u128, ContractAddress), u256>, // <(order_nonce, ContractAddress), u256>
        order_whitelist_count: LegacyMap<u128, u256>,
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
        AddressWhitelisted: AddressWhitelisted,
        AddressRemoved: AddressRemoved
    }

    #[derive(Drop, starknet::Event)]
    struct AddressWhitelisted {
        address: ContractAddress,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct AddressRemoved {
        address: ContractAddress,
        timestamp: u64,
    }

    #[abi(embed_v0)]
    impl StrategyPrivateSale of super::IStrategyPrivateSale<ContractState> {
        fn initializer(ref self: ContractState, fee: u128, owner: ContractAddress,) {
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

        fn add_address_to_whitelist(ref self: ContractState, order_nonce: u128, address: ContractAddress) {
            self.ownable.assert_only_owner();
            let index = self.order_whitelist_index.read((order_nonce, address));
            assert!(index.is_zero(), "PrivateSaleStrategy: address already whitelisted");

            let new_count = self.order_whitelist_count.read(order_nonce) + 1;

            self.order_whitelist_index.write((order_nonce, address), new_count);

            self.order_whitelist.write((order_nonce, new_count), address);

            self.order_whitelist_count.write(order_nonce, new_count);
            let timestamp = get_block_timestamp();
            self.emit(AddressWhitelisted { address, timestamp });
        }

        fn remove_address_from_whitelist(ref self: ContractState, order_nonce: u128, address: ContractAddress) {
            self.ownable.assert_only_owner();
            let index = self.order_whitelist_index.read((order_nonce, address));
            assert!(!index.is_zero(), "PrivateSaleStrategy: address not whitelisted");

            let count = self.order_whitelist_count.read(order_nonce);

            let address_at_last_index = self.order_whitelist.read((order_nonce, count));
            self.order_whitelist.write((order_nonce, index), address_at_last_index);
            self.order_whitelist.write((order_nonce, count), contract_address_const::<0>());
            self.order_whitelist_index.write((order_nonce, address), 0);

            if (count != 1) {
                self.order_whitelist_index.write((order_nonce, address_at_last_index), index);
            }

            self.order_whitelist_count.write(order_nonce, count - 1);
            let timestamp = get_block_timestamp();
            self.emit(AddressRemoved { address, timestamp });
        }

        fn is_address_whitelisted(self: @ContractState, order_nonce: u128, address: ContractAddress) -> bool {
            let index = self.order_whitelist_index.read((order_nonce, address));
            if (index == 0) {
                return false;
            }
            true
        }

        fn order_whitelist_count(self: @ContractState, order_nonce: u128) -> u256 {
            self.order_whitelist_count.read(order_nonce)
        }

        fn whitelisted_address(self: @ContractState, order_nonce: u128, index: u256) -> ContractAddress {
            self.order_whitelist.read((order_nonce, index))
        }

        fn can_execute_taker_ask(
            self: @ContractState,
            taker_ask: TakerOrder,
            maker_bid: MakerOrder,
            extra_params: Span<felt252>
        ) -> (bool, u256, u128) {
            let price_match: bool = maker_bid.price == taker_ask.price;
            let token_id_match: bool = maker_bid.token_id == taker_ask.token_id;
            let start_time_valid: bool = maker_bid.start_time < get_block_timestamp();
            let end_time_valid: bool = maker_bid.end_time > get_block_timestamp();
            let is_address_whitelisted: bool = self.is_address_whitelisted(maker_bid.salt_nonce, get_caller_address());
            if (price_match
                && token_id_match
                && start_time_valid
                && end_time_valid
                && is_address_whitelisted) {
                return (true, maker_bid.token_id, maker_bid.amount);
            } else {
                return (false, maker_bid.token_id, maker_bid.amount);
            }
        }

        fn can_execute_taker_bid(
            self: @ContractState, taker_bid: TakerOrder, maker_ask: MakerOrder
        ) -> (bool, u256, u128) {
            let price_match: bool = maker_ask.price == taker_bid.price;
            let token_id_match: bool = maker_ask.token_id == taker_bid.token_id;
            let start_time_valid: bool = maker_ask.start_time < get_block_timestamp();
            let end_time_valid: bool = maker_ask.end_time > get_block_timestamp();
            let is_address_whitelisted: bool = self.is_address_whitelisted(maker_ask.salt_nonce, get_caller_address());
            if (price_match
                && token_id_match
                && start_time_valid
                && end_time_valid
                && is_address_whitelisted) {
                return (true, maker_ask.token_id, maker_ask.amount);
            } else {
                return (false, maker_ask.token_id, maker_ask.amount);
            }
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradable._upgrade(impl_hash);
        }
    }
}
