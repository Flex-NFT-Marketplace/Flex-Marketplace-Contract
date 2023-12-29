use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
#[starknet::interface]
trait IERC1155TransferManager<TState> {
    fn initializer(ref self: TState, address: ContractAddress, owner: ContractAddress,);
    fn transfer_non_fungible_token(
        ref self: TState,
        collection: ContractAddress,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        amount: u128,
        data: Span<felt252>,
    );
    fn update_marketplace(ref self: TState, address: ContractAddress);
    fn get_marketplace(self: @TState) -> ContractAddress;
    fn upgrade(ref self: TState, impl_hash: ClassHash);
}

#[starknet::interface]
trait IERC1155<TContractState> {
    fn safe_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        id: u256,
        amount: u128,
        data: Span<felt252>
    );
}

#[starknet::contract]
mod ERC1155TransferManager {
    use starknet::{ContractAddress, contract_address_const};
    use super::ClassHash;
    use super::{IERC1155Dispatcher, IERC1155DispatcherTrait};
    use starknet::get_caller_address;
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
    impl ERC1155TransferManagerImpl of super::IERC1155TransferManager<ContractState> {
        fn initializer(ref self: ContractState, address: ContractAddress, owner: ContractAddress,) {
            self.ownable.initializer(owner);
            self.marketplace.write(address);
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
            assert(caller == marketplace, 'caller is not marketplace');
            IERC1155Dispatcher { contract_address: collection }
                .safe_transfer_from(from, to, token_id, amount, data);
        }

        fn update_marketplace(ref self: ContractState, address: ContractAddress) {
            self.ownable.assert_only_owner();
            self.marketplace.write(address);
        }

        fn get_marketplace(self: @ContractState) -> ContractAddress {
            self.marketplace.read()
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradable._upgrade(impl_hash);
        }
    }
}
