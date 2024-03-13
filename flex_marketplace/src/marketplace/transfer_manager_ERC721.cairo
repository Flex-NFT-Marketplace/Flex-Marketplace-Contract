use starknet::ContractAddress;

#[starknet::contract]
mod TransferManagerNFT {
    use starknet::{ContractAddress, get_caller_address};
    use flex::marketplace::interfaces::nft_transfer_manager::ITransferManagerNFT;
    use flex::{DebugContractAddress, DisplayContractAddress};
    use flex::marketplace::utils::order_types::{MakerOrder, TakerOrder};

    use openzeppelin::token::erc721::interface::{
        IERC721CamelOnlyDispatcher, IERC721CamelOnlyDispatcherTrait
    };
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
    impl TransferManagerNFTImpl of ITransferManagerNFT<ContractState> {
        fn initializer(
            ref self: ContractState,
            marketplace: ContractAddress,
            owner: ContractAddress,
        ) {
            // TODO: verify the role of Proxy here.
            self.marketplace.write(marketplace);
            self.ownable.initializer(owner);
        }

        fn transfer_non_fungible_token(
            ref self: ContractState,
            collection: ContractAddress,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            amount: u128,
            data: Span<felt252>,
        ) {
            let caller = get_caller_address();
            assert!(
                caller == self.get_marketplace(),
                "TransferManagerNFT: caller {} is not MarketPlace",
                caller
            );
            IERC721CamelOnlyDispatcher { contract_address: collection }
                .safeTransferFrom(from, to, token_id, data);
        }

        fn update_marketplace(ref self: ContractState, new_address: ContractAddress) {
            self.marketplace.write(new_address);
        }

        fn get_marketplace(self: @ContractState) -> ContractAddress {
            self.marketplace.read()
        }
    }
}
