use starknet::ContractAddress;

#[starknet::interface]
trait ITransferManagerNFT<TState> {
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
    fn get_marketplace(self: @TState) -> ContractAddress;
}

#[starknet::contract]
mod TransferManagerNFT {
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
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[external(v0)]
    impl TransferManagerNFTImpl of super::ITransferManagerNFT<ContractState> {
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

        fn get_marketplace(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }
    }
}
