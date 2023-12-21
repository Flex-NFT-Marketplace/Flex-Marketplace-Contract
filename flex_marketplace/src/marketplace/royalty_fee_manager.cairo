use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use flex::marketplace::royalty_fee_registry;
#[starknet::interface]
trait IRoyaltyFeeManager<TState> {
    fn initializer(ref self: TState, fee_registry: ContractAddress, owner: ContractAddress,);
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn get_owner(ref self: TState) -> ContractAddress;
    fn INTERFACE_ID_ERC2981(self: @TState) -> felt252;
    fn get_royalty_fee_registry(self: @TState) -> ContractAddress;
    fn calculate_royalty_fee_and_get_recipient(
        self: @TState, collection: ContractAddress, token_id: u256, amount: u128
    ) -> (ContractAddress, u128);
    fn upgrade(ref self: TState, impl_hash: ClassHash);
}

#[starknet::interface]
trait IERC165<TContractState> {
    fn supportsInterface(ref self: TContractState, interfaceId: felt252) -> bool;
}

#[starknet::interface]
trait IERC2981<TContractState> {
    fn royaltyInfo(
        ref self: TContractState, tokenId: u256, salePrice: u128
    ) -> (ContractAddress, u128);
}

#[starknet::contract]
mod RoyaltyFeeManager {
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait;
    use openzeppelin::access::ownable::interface::IOwnable;
    use starknet::{ContractAddress, contract_address_const};
    use super::royalty_fee_registry::IRoyaltyFeeRegistryDispatcher;
    use super::royalty_fee_registry::IRoyaltyFeeRegistryDispatcherTrait;
    use super::IERC165Dispatcher;
    use super::IERC165DispatcherTrait;
    use super::IERC2981Dispatcher;
    use super::IERC2981DispatcherTrait;
    use super::ClassHash;
    use zeroable::Zeroable;
    use starknet::get_caller_address;


    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        INTERFACE_ID_ERC2981: felt252,
        royalty_fee_registry: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnableEvent: OwnableComponent::Event,
    }

    #[external(v0)]
    impl RoyaltyFeeManagerImpl of super::IRoyaltyFeeManager<ContractState> {
        fn initializer(
            ref self: ContractState, fee_registry: ContractAddress, owner: ContractAddress,
        ) {
            self.INTERFACE_ID_ERC2981.write(0x2a55205a);
            self.royalty_fee_registry.write(fee_registry);
            self.ownable.initializer(owner);
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            self.ownable.transfer_ownership(new_owner);
        }

        fn get_owner(ref self: ContractState) -> ContractAddress {
            return self.ownable.owner();
        }

        fn INTERFACE_ID_ERC2981(self: @ContractState) -> felt252 {
            return self.INTERFACE_ID_ERC2981.read();
        }

        fn get_royalty_fee_registry(self: @ContractState) -> ContractAddress {
            return self.royalty_fee_registry.read();
        }

        fn calculate_royalty_fee_and_get_recipient(
            self: @ContractState, collection: ContractAddress, token_id: u256, amount: u128
        ) -> (ContractAddress, u128) {
            let feeRegistry = self.get_royalty_fee_registry();
            let (receiver, royaltyAmount) = IRoyaltyFeeRegistryDispatcher {
                contract_address: feeRegistry
            }
                .get_royalty_fee_info(collection, amount);
            if (!receiver.is_zero()) {
                return (receiver, royaltyAmount);
            }
            let interfaceIDERC2981 = self.INTERFACE_ID_ERC2981();
            let supportsERC2981: bool = IERC165Dispatcher { contract_address: collection }
                .supportsInterface(interfaceIDERC2981);
            if (supportsERC2981) {
                let (receiverERC2981, royaltyAmountERC2981) = IERC2981Dispatcher {
                    contract_address: collection
                }
                    .royaltyInfo(token_id, amount);
                return (receiverERC2981, royaltyAmountERC2981);
            }
            return (receiver, royaltyAmount);
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.ownable.assert_only_owner();
            assert(!impl_hash.is_zero(), 'Class hash cannot be zero');
            starknet::replace_class_syscall(impl_hash).unwrap();
        }
    }
}
