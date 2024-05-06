use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use flex::marketplace::royalty_fee_registry::{
    IRoyaltyFeeRegistryDispatcher, IRoyaltyFeeRegistryDispatcherTrait
};
#[starknet::interface]
trait IRoyaltyFeeManager<TState> {
    fn initializer(ref self: TState, fee_registry: ContractAddress, owner: ContractAddress,);
    fn upgrade(ref self: TState, impl_hash: ClassHash);
    fn INTERFACE_ID_ERC2981(self: @TState) -> felt252;
    fn calculate_royalty_fee_and_get_recipient(
        self: @TState, collection: ContractAddress, token_id: u256, amount: u128
    ) -> (ContractAddress, u128);
    fn get_royalty_fee_registry(self: @TState) -> IRoyaltyFeeRegistryDispatcher;
}


#[starknet::interface]
trait IERC2981<TContractState> {
    fn royaltyInfo(
        ref self: TContractState, tokenId: u256, salePrice: u128
    ) -> (ContractAddress, u128);
}

#[starknet::contract]
mod RoyaltyFeeManager {
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent::InternalTrait;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};
    use starknet::get_caller_address;
    use starknet::{ContractAddress, contract_address_const};
    use super::ClassHash;
    use super::IERC2981Dispatcher;
    use super::IERC2981DispatcherTrait;
    use super::{IRoyaltyFeeRegistryDispatcher, IRoyaltyFeeRegistryDispatcherTrait};
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        INTERFACE_ID_ERC2981: felt252,
        royalty_fee_registry: IRoyaltyFeeRegistryDispatcher,
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

    #[abi(embed_v0)]
    impl RoyaltyFeeManagerImpl of super::IRoyaltyFeeManager<ContractState> {
        fn initializer(
            ref self: ContractState, fee_registry: ContractAddress, owner: ContractAddress,
        ) {
            self.INTERFACE_ID_ERC2981.write(0x2a55205a);
            self
                .royalty_fee_registry
                .write(IRoyaltyFeeRegistryDispatcher { contract_address: fee_registry });
            self.ownable.initializer(owner);
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradable._upgrade(impl_hash);
        }

        fn INTERFACE_ID_ERC2981(self: @ContractState) -> felt252 {
            return self.INTERFACE_ID_ERC2981.read();
        }

        fn calculate_royalty_fee_and_get_recipient(
            self: @ContractState, collection: ContractAddress, token_id: u256, amount: u128
        ) -> (ContractAddress, u128) {
            let feeRegistry = self.get_royalty_fee_registry();
            let (receiver, royaltyAmount) = feeRegistry.get_royalty_fee_info(collection, amount);
            if (!receiver.is_zero()) {
                return (receiver, royaltyAmount);
            }
            let interfaceIDERC2981 = self.INTERFACE_ID_ERC2981();
            let supportsERC2981: bool = ISRC5Dispatcher { contract_address: collection }
                .supports_interface(interfaceIDERC2981);
            if (supportsERC2981) {
                let (receiverERC2981, royaltyAmountERC2981) = IERC2981Dispatcher {
                    contract_address: collection
                }
                    .royaltyInfo(token_id, amount);
                return (receiverERC2981, royaltyAmountERC2981);
            }
            return (receiver, royaltyAmount);
        }

        fn get_royalty_fee_registry(self: @ContractState) -> IRoyaltyFeeRegistryDispatcher {
            return self.royalty_fee_registry.read();
        }
    }
}
