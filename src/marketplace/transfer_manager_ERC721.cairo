use starknet::ContractAddress;

#[starknet::interface]
trait ITransferManagerNFT<TState> {
    fn initializer(
        ref self: TState,
        marketplace: ContractAddress,
        owner: ContractAddress,
    );
    fn transfer_non_fungible_token(
        ref self: TState,
        collection: ContractAddress,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        amount: u128
    );
    fn update_marketplace(ref self: TState, new_address: ContractAddress);
    fn get_marketplace(self: @TState) -> ContractAddress;
}

#[starknet::contract]
mod TransferManagerNFT {
    use starknet::{ContractAddress, get_caller_address};

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
        initialized: bool,
        marketplace: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        marketplace: ContractAddress,
        owner: ContractAddress,
    ) {
        self.initializer(marketplace, owner);
    }

    #[external(v0)]
    impl TransferManagerNFTImpl of super::ITransferManagerNFT<ContractState> {
        fn initializer(
            ref self: ContractState,
            marketplace: ContractAddress,
            owner: ContractAddress,
        ) {
            assert!(!self.initialized.read(), "TransferManagerNFTImpl: already initialized");
            self.initialized.write(true);
            self.marketplace.write(marketplace);
            self.ownable.initializer(owner);
        }

        fn transfer_non_fungible_token(
            ref self: ContractState,
            collection: ContractAddress,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            amount: u128
        ) {
            let caller = get_caller_address();
            assert!(
                caller == self.get_marketplace(),
                "ERC721TransferManager: caller {} is not MarketPlace",
                caller
            );
            IERC721CamelOnlyDispatcher { contract_address: collection }
                .transferFrom(from, to, token_id);
        }

        fn update_marketplace(ref self: ContractState, new_address: ContractAddress) {
            self.ownable.assert_only_owner();
            self.marketplace.write(new_address);
        }

        fn get_marketplace(self: @ContractState) -> ContractAddress {
            self.marketplace.read()
        }
    }
}
