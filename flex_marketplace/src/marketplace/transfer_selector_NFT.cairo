use starknet::ContractAddress;

#[starknet::interface]
trait ITransferSelectorNFT<TState> {
    fn initializer(
        ref self: TState,
        transfer_manager_ERC721: ContractAddress,
        transfer_manager_ERC1155: ContractAddress,
        owner: ContractAddress,
        proxy_admin: ContractAddress
    );
    fn add_collection_transfer_manager(
        ref self: TState, collection: ContractAddress, transfer_manger: ContractAddress
    );
    fn remove_collection_transfer_manager(ref self: TState, collection: ContractAddress);
    fn update_TRANSFER_MANAGER_ERC721(ref self: TState, manager: ContractAddress);
    fn update_TRANSFER_MANAGER_ERC1155(ref self: TState, manager: ContractAddress);
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn owner(self: @TState) -> ContractAddress;
    fn get_INTERFACE_ID_ERC721(self: @TState) -> felt252;
    fn get_INTERFACE_ID_ERC1155(self: @TState) -> felt252;
    fn get_TRANSFER_MANAGER_ERC721(self: @TState) -> ContractAddress;
    fn get_TRANSFER_MANAGER_ERC1155(self: @TState) -> ContractAddress;
    fn transfer_manager_selector_for_collection(
        self: @TState, collection: ContractAddress
    ) -> ContractAddress;
    fn check_transfer_manager_for_token(
        self: @TState, collection: ContractAddress
    ) -> ContractAddress;
}

#[starknet::contract]
mod TransferSelectorNFT {
    use flex::marketplace::utils::order_types::{MakerOrder, TakerOrder};

    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::{ContractAddress, contract_address_const};
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        INTERFACE_ID_ERC721: felt252,
        INTERFACE_ID_ERC1155: felt252,
        TRANSFER_MANAGER_ERC721: ContractAddress,
        TRANSFER_MANAGER_ERC1155: ContractAddress,
        transfer_manager_selector_for_collection: felt252,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CollectionTransferManagerAdded: CollectionTransferManagerAdded,
        CollectionTransferManagerRemoved: CollectionTransferManagerRemoved,
        OwnableEvent: OwnableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    struct CollectionTransferManagerAdded {
        collection: ContractAddress,
        transfer_manager: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct CollectionTransferManagerRemoved {
        collection: ContractAddress,
        timestamp: u64
    }


    #[external(v0)]
    impl TransferSelectorNFTImpl of super::ITransferSelectorNFT<ContractState> {
        fn initializer(
            ref self: ContractState,
            transfer_manager_ERC721: ContractAddress,
            transfer_manager_ERC1155: ContractAddress,
            owner: ContractAddress,
            proxy_admin: ContractAddress
        ) { // TODO
        }

        fn add_collection_transfer_manager(
            ref self: ContractState, collection: ContractAddress, transfer_manger: ContractAddress
        ) { // TODO
        }

        fn remove_collection_transfer_manager(
            ref self: ContractState, collection: ContractAddress
        ) { // TODO
        }

        fn update_TRANSFER_MANAGER_ERC721(
            ref self: ContractState, manager: ContractAddress
        ) { // TODO
        }

        fn update_TRANSFER_MANAGER_ERC1155(
            ref self: ContractState, manager: ContractAddress
        ) { // TODO
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) { // TODO
        }

        fn owner(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn get_INTERFACE_ID_ERC721(self: @ContractState) -> felt252 {
            // TODO
            0
        }

        fn get_INTERFACE_ID_ERC1155(self: @ContractState) -> felt252 {
            // TODO
            0
        }

        fn get_TRANSFER_MANAGER_ERC721(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn get_TRANSFER_MANAGER_ERC1155(self: @ContractState) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn transfer_manager_selector_for_collection(
            self: @ContractState, collection: ContractAddress
        ) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }

        fn check_transfer_manager_for_token(
            self: @ContractState, collection: ContractAddress
        ) -> ContractAddress {
            // TODO
            contract_address_const::<0>()
        }
    }
}
