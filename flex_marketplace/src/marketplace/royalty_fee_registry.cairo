use starknet::ContractAddress;

#[starknet::interface]
trait IRoyaltyFeeRegistry<TState> {
    fn initializer(
        ref self: TState, fee_limit: u128, owner: ContractAddress, proxy_admim: ContractAddress
    );
    fn update_royalty_fee_limit(ref self: TState, fee_limit: u128);
    fn update_royalty_info_collection(
        ref self: TState,
        collection: ContractAddress,
        setter: ContractAddress,
        receiver: ContractAddress,
        fee: u128
    );
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn owner(ref self: TState) -> ContractAddress;
    fn get_royalty_fee_limit(self: @TState) -> u128;
    fn get_royalty_fee_info(self: @TState) -> (ContractAddress, u128);
    fn get_royalty_fee_info_collection(
        self: @TState, collection: ContractAddress
    ) -> (ContractAddress, ContractAddress, u128);
}

#[starknet::contract]
mod RoyaltyFeeRegistry {
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::{ContractAddress, contract_address_const};
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
        royalty_fee_limit: u128,
        royalty_fee_info_collection: LegacyMap::<felt252, FeeInfo>,
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
        receive: ContractAddress,
        fee: u128,
        timestamp: u64,
    }

    #[external(v0)]
    impl RoyaltyFeeRegistryImpl of super::IRoyaltyFeeRegistry<ContractState> {
        fn initializer(
            ref self: ContractState,
            fee_limit: u128,
            owner: ContractAddress,
            proxy_admim: ContractAddress
        ) { // TODO
        }

        fn update_royalty_fee_limit(ref self: ContractState, fee_limit: u128) { // TODO
        }

        fn update_royalty_info_collection(
            ref self: ContractState,
            collection: ContractAddress,
            setter: ContractAddress,
            receiver: ContractAddress,
            fee: u128
        ) { // TODO
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) { // TODO
        }

        fn owner(ref self: ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn get_royalty_fee_limit(self: @ContractState) -> u128 {
            // TODO
            0
        }

        fn get_royalty_fee_info(self: @ContractState) -> (ContractAddress, u128) {
            // TODO
            (contract_address_const::<0>(), 0)
        }

        fn get_royalty_fee_info_collection(
            self: @ContractState, collection: ContractAddress
        ) -> (ContractAddress, ContractAddress, u128) {
            // TODO
            (contract_address_const::<0>(), contract_address_const::<0>(), 0)
        }
    }
}
