use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use marketplace::utils::order_types::{TakerOrder, MakerOrder};

#[starknet::interface]
trait IStrategyPrivateSale<TState> {
    fn initializer(ref self: TState, fee: u128, owner: ContractAddress);
    fn update_protocol_fee(ref self: TState, fee: u128);
    fn protocol_fee(self: @TState) -> u128;
    fn add_address_to_whitelist(ref self: TState, address: ContractAddress);
    fn remove_address_from_whitelist(ref self: TState, address: ContractAddress);
    fn is_address_whitelisted(self: @TState, address: ContractAddress) -> bool;
    fn whitelisted_addresses_count(self: @TState) -> usize;
    fn whitelisted_address(self: @TState, index: usize) -> ContractAddress;
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
        whitelisted_addresses: LegacyMap<u32, ContractAddress>,
        whitelisted_address_index: LegacyMap<ContractAddress, u32>,
        whitelisted_addresses_count: u32,
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

        fn add_address_to_whitelist(ref self: ContractState, address: ContractAddress) {
            self.ownable.assert_only_owner();
            let index = self.whitelisted_address_index.read(address);
            assert!(index.is_zero(), "PrivateSaleStrategy: address already whitelisted");
            let new_count = self.whitelisted_addresses_count.read() + 1;
            self.whitelisted_address_index.write(address, new_count);
            self.whitelisted_addresses.write(new_count, address);
            self.whitelisted_addresses_count.write(new_count);
            let timestamp = get_block_timestamp();
            self.emit(AddressWhitelisted { address, timestamp });
        }

        fn remove_address_from_whitelist(ref self: ContractState, address: ContractAddress) {
            self.ownable.assert_only_owner();
            let index = self.whitelisted_address_index.read(address);
            assert!(!index.is_zero(), "PrivateSaleStrategy: address not whitelisted");
            let count = self.whitelisted_addresses_count.read();

            let address_at_last_index = self.whitelisted_addresses.read(count);
            self.whitelisted_addresses.write(index, address_at_last_index);
            self.whitelisted_addresses.write(count, contract_address_const::<0>());
            self.whitelisted_address_index.write(address, 0);

            if (count != 1) {
                self.whitelisted_address_index.write(address_at_last_index, index);
            }
            self.whitelisted_addresses_count.write(count - 1);
            let timestamp = get_block_timestamp();
            self.emit(AddressRemoved { address, timestamp });
        }

        fn is_address_whitelisted(self: @ContractState, address: ContractAddress) -> bool {
            let index = self.whitelisted_address_index.read(address);
            if (index == 0) {
                return false;
            }
            true
        }

        fn whitelisted_addresses_count(self: @ContractState) -> usize {
            self.whitelisted_addresses_count.read()
        }

        fn whitelisted_address(self: @ContractState, index: usize) -> ContractAddress {
            self.whitelisted_addresses.read(index)
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
            let is_address_whitelisted: bool = self.is_address_whitelisted(get_caller_address());
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
            let is_address_whitelisted: bool = self.is_address_whitelisted(get_caller_address());
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
