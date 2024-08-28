use starknet::ContractAddress;

#[starknet::interface]
trait ITransferSelectorNFT<TState> {
    fn initializer(
        ref self: TState,
        transfer_manager_ERC721: ContractAddress,
        transfer_manager_ERC1155: ContractAddress,
        owner: ContractAddress,
    );
    fn add_collection_transfer_manager(
        ref self: TState, collection: ContractAddress, transfer_manager: ContractAddress
    );
    fn remove_collection_transfer_manager(ref self: TState, collection: ContractAddress);
    fn update_TRANSFER_MANAGER_ERC721(ref self: TState, manager: ContractAddress);
    fn update_TRANSFER_MANAGER_ERC1155(ref self: TState, manager: ContractAddress);
    fn get_INTERFACE_ID_ERC721(self: @TState) -> felt252;
    fn get_INTERFACE_ID_ERC1155(self: @TState) -> felt252;
    fn get_TRANSFER_MANAGER_ERC721(self: @TState) -> ContractAddress;
    fn get_TRANSFER_MANAGER_ERC1155(self: @TState) -> ContractAddress;
    fn get_transfer_manager_selector_for_collection(
        self: @TState, collection: ContractAddress
    ) -> ContractAddress;
    fn check_transfer_manager_for_token(
        self: @TState, collection: ContractAddress
    ) -> ContractAddress;
}

#[starknet::contract]
mod TransferSelectorNFT {
    use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

    use marketplace::{DebugContractAddress, DisplayContractAddress};
    use marketplace::utils::order_types::{MakerOrder, TakerOrder};
    use marketplace::mocks::erc1155::IERC1155_ID;
    use openzeppelin::token::erc721::interface::IERC721_ID;
    use openzeppelin::introspection::interface::{ISRC5CamelDispatcher, ISRC5CamelDispatcherTrait};
    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    use snforge_std::PrintTrait;

    #[storage]
    struct Storage {
        initialized: bool,
        INTERFACE_ID_ERC721: felt252,
        INTERFACE_ID_ERC1155: felt252,
        TRANSFER_MANAGER_ERC721: ContractAddress,
        TRANSFER_MANAGER_ERC1155: ContractAddress,
        transfer_manager_selector_for_collection: LegacyMap::<ContractAddress, ContractAddress>,
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


    #[abi(embed_v0)]
    impl TransferSelectorNFTImpl of super::ITransferSelectorNFT<ContractState> {
        fn initializer(
            ref self: ContractState,
            transfer_manager_ERC721: ContractAddress,
            transfer_manager_ERC1155: ContractAddress,
            owner: ContractAddress,
        ) {
            assert!(!self.initialized.read(), "TransferSelectorNFT: already initialized");
            self.initialized.write(true);
            self.INTERFACE_ID_ERC721.write(IERC721_ID);
            self.INTERFACE_ID_ERC1155.write(IERC1155_ID);
            self.TRANSFER_MANAGER_ERC721.write(transfer_manager_ERC721);
            self.TRANSFER_MANAGER_ERC1155.write(transfer_manager_ERC1155);
            self.ownable.initializer(owner);
        }

        fn add_collection_transfer_manager(
            ref self: ContractState, collection: ContractAddress, transfer_manager: ContractAddress
        ) {
            self.ownable.assert_only_owner();
            assert!(
                !collection.is_zero(), "TransferSelectorNFT: invalid collection {}", collection
            );
            assert!(
                !transfer_manager.is_zero(),
                "TransferSelectorNFT: invalid transfer manager {}",
                transfer_manager
            );
            self.transfer_manager_selector_for_collection.write(collection, transfer_manager);
            self
                .emit(
                    CollectionTransferManagerAdded {
                        collection, transfer_manager, timestamp: get_block_timestamp()
                    }
                );
        }

        fn remove_collection_transfer_manager(
            ref self: ContractState, collection: ContractAddress
        ) {
            self.ownable.assert_only_owner();
            let transfer_manager = self.transfer_manager_selector_for_collection.read(collection);
            assert!(
                !transfer_manager.is_zero(),
                "TransferSelectorNFT: tried to remove an invalid transfer manager: {}",
                transfer_manager
            );
            self
                .transfer_manager_selector_for_collection
                .write(collection, contract_address_const::<0>());
            self
                .emit(
                    CollectionTransferManagerRemoved {
                        collection, timestamp: get_block_timestamp()
                    }
                );
        }

        fn update_TRANSFER_MANAGER_ERC721(ref self: ContractState, manager: ContractAddress) {
            self.ownable.assert_only_owner();
            self.TRANSFER_MANAGER_ERC721.write(manager);
        }

        fn update_TRANSFER_MANAGER_ERC1155(ref self: ContractState, manager: ContractAddress) {
            self.ownable.assert_only_owner();
            self.TRANSFER_MANAGER_ERC1155.write(manager);
        }

        fn get_INTERFACE_ID_ERC721(self: @ContractState) -> felt252 {
            self.INTERFACE_ID_ERC721.read()
        }

        fn get_INTERFACE_ID_ERC1155(self: @ContractState) -> felt252 {
            self.INTERFACE_ID_ERC1155.read()
        }

        fn get_TRANSFER_MANAGER_ERC721(self: @ContractState) -> ContractAddress {
            self.TRANSFER_MANAGER_ERC721.read()
        }

        fn get_TRANSFER_MANAGER_ERC1155(self: @ContractState) -> ContractAddress {
            self.TRANSFER_MANAGER_ERC1155.read()
        }

        fn get_transfer_manager_selector_for_collection(
            self: @ContractState, collection: ContractAddress
        ) -> ContractAddress {
            self.transfer_manager_selector_for_collection.read(collection)
        }

        fn check_transfer_manager_for_token(
            self: @ContractState, collection: ContractAddress
        ) -> ContractAddress {
            let transfer_manager = self.transfer_manager_selector_for_collection.read(collection);
            if !transfer_manager.is_zero() {
                return transfer_manager;
            }

            let transfer_manager_ERC721 = self.get_TRANSFER_MANAGER_ERC721();
            let supports_ERC721 = ISRC5CamelDispatcher { contract_address: collection }
                .supportsInterface(self.INTERFACE_ID_ERC721.read());
            if supports_ERC721 {
                return transfer_manager_ERC721;
            }

            let transfer_manager_ERC1155 = self.get_TRANSFER_MANAGER_ERC1155();
            let supports_ERC1155 = ISRC5CamelDispatcher { contract_address: collection }
                .supportsInterface(self.INTERFACE_ID_ERC1155.read());
            if supports_ERC1155 {
                return transfer_manager_ERC1155;
            }
            return contract_address_const::<0>();
        }
    }
}
