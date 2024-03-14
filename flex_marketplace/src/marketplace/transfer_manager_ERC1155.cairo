#[starknet::contract]
mod ERC1155TransferManager {
    use starknet::{ContractAddress, ClassHash, contract_address_const, get_caller_address};

    use flex::marketplace::interfaces::nft_transfer_manager::ITransferManagerNFT;
    use flex::{DebugContractAddress, DisplayContractAddress};
    use flex::mocks::erc1155::{IERC1155Dispatcher, IERC1155DispatcherTrait};

    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    component!(path: UpgradeableComponent, storage: upgradable, event: UpgradeableEvent);
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent::InternalTrait;
    use openzeppelin::upgrades::UpgradeableComponent;


    #[storage]
    struct Storage {
        marketplace: ContractAddress,
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
    }

    #[external(v0)]
    impl ERC1155TransferManagerImpl of ITransferManagerNFT<ContractState> {
        fn initializer(
            ref self: ContractState, marketplace: ContractAddress, owner: ContractAddress,
        ) {
            self.ownable.initializer(owner);
            self.marketplace.write(marketplace);
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
            let caller: ContractAddress = get_caller_address();
            let marketplace: ContractAddress = self.get_marketplace();
            assert!(
                caller == marketplace,
                "ERC1155TransferManager: caller {} is not marketplace",
                caller
            );
            IERC1155Dispatcher { contract_address: collection }
                .safe_transfer_from(from, to, token_id, amount, data);
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
