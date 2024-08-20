use starknet::ContractAddress;

#[starknet::interface]
trait IRoyaltyFeeRegistry<TState> {
    fn initializer(ref self: TState, fee_limit: u128, owner: ContractAddress);
    fn update_royalty_fee_limit(ref self: TState, fee_limit: u128);
    fn update_royalty_info_collection(
        ref self: TState,
        collection: ContractAddress,
        setter: ContractAddress,
        receiver: ContractAddress,
        fee: u128
    );
    fn get_royalty_fee_limit(self: @TState) -> u128;
    fn get_royalty_fee_info(
        self: @TState, collection: ContractAddress, amount: u128
    ) -> (ContractAddress, u128);
    fn get_royalty_fee_info_collection(
        self: @TState, collection: ContractAddress
    ) -> (ContractAddress, ContractAddress, u128);
}

#[starknet::contract]
mod RoyaltyFeeRegistry {
    use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[derive(Drop, Serde, starknet::Store)]
    struct FeeInfo {
        setter: ContractAddress,
        receiver: ContractAddress,
        fee: u128
    }

    #[storage]
    struct Storage {
        initialized: bool,
        royalty_fee_limit: u128,
        royalty_fee_info_collection: LegacyMap::<ContractAddress, FeeInfo>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        NewRoyaltyFeeLimit: NewRoyaltyFeeLimit,
        RoyaltyFeeUpdate: RoyaltyFeeUpdate,
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct NewRoyaltyFeeLimit {
        fee_limit: u128,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct RoyaltyFeeUpdate {
        collection: ContractAddress,
        setter: ContractAddress,
        receiver: ContractAddress,
        fee: u128,
        timestamp: u64,
    }

    #[abi(embed_v0)]
    impl RoyaltyFeeRegistryImpl of super::IRoyaltyFeeRegistry<ContractState> {
        fn initializer(ref self: ContractState, fee_limit: u128, owner: ContractAddress,) {
            assert!(!self.initialized.read(), "RoyaltyFeeRegistry: already initialized");
            self.initialized.write(true);
            assert!(
                fee_limit <= 9500, "RoyaltyFeeRegistry: fee_limit {} exceeds MAX_FEE", fee_limit
            );
            self.ownable.initializer(owner)
        }

        fn update_royalty_fee_limit(ref self: ContractState, fee_limit: u128) {
            self.ownable.assert_only_owner();
            assert!(
                fee_limit <= 9500, "RoyaltyFeeRegistry: fee_limit {} exceeds MAX_FEE", fee_limit
            );
            self.royalty_fee_limit.write(fee_limit);
            self.emit(NewRoyaltyFeeLimit { fee_limit, timestamp: get_block_timestamp() });
        }

        fn update_royalty_info_collection(
            ref self: ContractState,
            collection: ContractAddress,
            setter: ContractAddress,
            receiver: ContractAddress,
            fee: u128
        ) {
            self.ownable.assert_only_owner();
            let fee_limit = self.get_royalty_fee_limit();
            assert!(
                fee <= fee_limit, "RoyaltyFeeRegistry: fee {} exceeds fee limit {}", fee, fee_limit
            );
            self.royalty_fee_info_collection.write(collection, FeeInfo { setter, receiver, fee });
            self
                .emit(
                    RoyaltyFeeUpdate {
                        collection, setter, receiver, fee, timestamp: get_block_timestamp()
                    }
                );
        }

        fn get_royalty_fee_limit(self: @ContractState) -> u128 {
            self.royalty_fee_limit.read()
        }

        fn get_royalty_fee_info(
            self: @ContractState, collection: ContractAddress, amount: u128
        ) -> (ContractAddress, u128) {
            let fee_info = self.royalty_fee_info_collection.read(collection);
            let royalty_amount = amount * fee_info.fee / 10_000;
            (fee_info.receiver, royalty_amount)
        }

        fn get_royalty_fee_info_collection(
            self: @ContractState, collection: ContractAddress
        ) -> (ContractAddress, ContractAddress, u128) {
            let fee_info = self.royalty_fee_info_collection.read(collection);
            (fee_info.setter, fee_info.receiver, fee_info.fee)
        }
    }
}
