use starknet::ContractAddress;

#[starknet::interface]
trait IERC1155<TState> {
    fn initializer(
        ref self: TState,
        address: ContractAddress,
        owner: ContractAddress,
        proxy_admin: ContractAddress
    );
    fn transfer_non_fungible_token(
        ref self: TState,
        collection: ContractAddress,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        amount: u128
    );
    fn update_marketplace(ref self: TState, address: ContractAddress);
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn owner(self: @TState) -> ContractAddress;
    fn get_marketplace(self: @TState) -> ContractAddress;
}

#[starknet::contract]
mod ERC1155 {
    use starknet::{ContractAddress, contract_address_const};

    use flex::marketplace::utils::order_types::{MakerOrder, TakerOrder};

    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        marketplace: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnableEvent: OwnableComponent::Event
    }

    #[external(v0)]
    impl ERC1155Impl of super::IERC1155<ContractState> {
        fn initializer(
            ref self: ContractState,
            address: ContractAddress,
            owner: ContractAddress,
            proxy_admin: ContractAddress
        ) { // TODO
        }

        fn transfer_non_fungible_token(
            ref self: ContractState,
            collection: ContractAddress,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            amount: u128
        ) { // TODO
        }

        fn update_marketplace(ref self: ContractState, address: ContractAddress) { // TODO
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) { // TODO
        }

        fn owner(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn get_marketplace(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }
    }
}
