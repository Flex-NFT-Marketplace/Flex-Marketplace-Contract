use starknet::ContractAddress;

#[starknet::interface]
trait IRoyaltyFeeManager<TState> {
    fn initializer(
        ref self: TState,
        fee_registry: ContractAddress,
        owner: ContractAddress,
        proxy_admin: ContractAddress
    );
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn owner(ref self: TState) -> ContractAddress;
    fn INTERFACE_ID_ERC2981(self: @TState) -> felt252;
    fn get_royalty_fee_registry(self: @TState) -> ContractAddress;
    fn calculate_royalty_fee_and_get_recipient(
        self: @TState, collection: ContractAddress, token_id: u256, amount: u128
    ) -> (ContractAddress, u128);
}

#[starknet::contract]
mod RoyaltyFeeManager {
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::{ContractAddress, contract_address_const};
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        INTERFACE_ID_ERC2981: felt252,
        royalty_fee_registry: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnableEvent: OwnableComponent::Event,
    }

    #[external(v0)]
    impl RoyaltyFeeManagerImpl of super::IRoyaltyFeeManager<ContractState> {
        fn initializer(
            ref self: ContractState,
            fee_registry: ContractAddress,
            owner: ContractAddress,
            proxy_admin: ContractAddress
        ) { // TODO
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) { // TODO
        }

        fn owner(ref self: ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn INTERFACE_ID_ERC2981(self: @ContractState) -> felt252 {
            // TODO
            0
        }

        fn get_royalty_fee_registry(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn calculate_royalty_fee_and_get_recipient(
            self: @ContractState, collection: ContractAddress, token_id: u256, amount: u128
        ) -> (ContractAddress, u128) {
            // TODO
            (contract_address_const::<0>(), 0)
        }
    }
}
