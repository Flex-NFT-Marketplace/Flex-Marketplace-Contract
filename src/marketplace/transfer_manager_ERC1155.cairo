use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
#[starknet::interface]
trait IERC1155TransferManager<TState> {
    fn initializer(ref self: TState, marketplace: ContractAddress, owner: ContractAddress,);
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
mod ERC1155TransferManager {
    use starknet::{ContractAddress, contract_address_const, get_caller_address};

    use super::ClassHash;
    use flex::{DebugContractAddress, DisplayContractAddress};
    use flex::mocks::erc1155::{IERC1155Dispatcher, IERC1155DispatcherTrait};

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
        OwnableEvent: OwnableComponent::Event,
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
    impl ERC1155TransferManagerImpl of super::IERC1155TransferManager<ContractState> {
        fn initializer(
            ref self: ContractState,
            marketplace: ContractAddress,
            owner: ContractAddress,
        ) {
            assert!(!self.initialized.read(), "ERC1155TransferManager: already initialized");
            self.initialized.write(true);
            self.ownable.initializer(owner);
            self.marketplace.write(marketplace);
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
                "ERC1155TransferManager: caller {} is not marketplace",
                caller
            );
            let data: Array<u8> = array![];
            let current_low_u128: u128 = amount.try_into().unwrap();
            let current_high = 0;
            let current_high_u128: u128 = current_high.try_into().unwrap();
            let amount_u256 = u256 {
                low: current_low_u128,
                high: current_high_u128
            };
            IERC1155Dispatcher { contract_address: collection }
                .safe_transfer_from(from, to, token_id, amount_u256, data);
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
